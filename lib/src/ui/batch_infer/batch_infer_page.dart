import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/batch_infer/batch_infer_cubit.dart';
import 'package:rwkv_studio/src/ui/batch_infer/text_painter.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

extension _ on BuildContext {
  BatchInferCubit get cubit => BlocProvider.of<BatchInferCubit>(this);
}

class BatchInferPage extends StatelessWidget {
  const BatchInferPage._();

  static Widget create() => BlocProvider<BatchInferCubit>(
    create: (context) => BatchInferCubit(),
    child: const BatchInferPage._(),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 12, vertical: 12),
      child: Column(
        mainAxisSize: .max,
        crossAxisAlignment: .stretch,
        children: [
          _ToolBar(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<BatchInferCubit, BatchInferState>(
                  buildWhen: (prev, cur) =>
                      cur.textController != prev.textController,
                  builder: (context, state) {
                    return TextBox(controller: state.textController);
                  },
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<BatchInferCubit, BatchInferState>(
                buildWhen: (prev, cur) => cur.isRunning != prev.isRunning,
                builder: (context, state) {
                  return FilledButton(
                    child: state.isRunning
                        ? const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: ProgressRing(strokeWidth: 2),
                              ),
                              SizedBox(width: 4),
                              Text('停止'),
                            ],
                          )
                        : const Text('提交'),
                    onPressed: () {
                      if (!state.isRunning) {
                        context.cubit.submit();
                      } else {
                        context.cubit.stop();
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RepaintBoundary(
              child: BlocBuilder<BatchInferCubit, BatchInferState>(
                buildWhen: (prev, cur) =>
                    cur.cells != prev.cells || cur.setting != prev.setting,
                builder: (context, state) {
                  return CustomPaint(
                    willChange: true,
                    painter: GridBackgroundPainter(
                      rows: state.setting.row,
                      cols: state.setting.col,
                    ),
                    foregroundPainter: GridTailParagraphPainter(
                      cells: state.cells,
                      rows: state.setting.row,
                      cols: state.setting.col,
                      colSpacing: 2,
                      rowSpacing: 2,
                      textStyle: const TextStyle(
                        fontSize: 10,
                        height: 1,
                        letterSpacing: 1,
                        color: Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text('并行模式', style: context.fluent.typography.subtitle),
        ),
        SizedBox(
          height: 34,
          child: BlocSelector<BatchInferCubit, BatchInferState, ModelLoadState>(
            selector: (state) => state.modelState,
            builder: (context, state) {
              return ModelSelector(
                modelState: state,
                onModelSelected: (s) {
                  context.cubit
                      .loadModel(context, context.rwkv, s)
                      .withToast(context);
                },
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: BlocSelector<BatchInferCubit, BatchInferState, BatchSizeState>(
            selector: (state) => state.setting,
            builder: (context, state) {
              return ComboBox(
                onChanged: (v) {
                  context.cubit.setBatchSize(v!);
                },
                items: [
                  for (var v in BatchSizeState.all)
                    ComboBoxItem(
                      value: v,
                      child: Text('${v.size} 路并行 (${v.row}x${v.col})'),
                    ),
                ],
                value: state,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: BlocBuilder<AppCubit, AppState>(
            buildWhen: (prev, cur) => cur.fullScreen != prev.fullScreen,
            builder: (context, state) {
              return Button(
                child: Text(state.fullScreen ? '退出全屏' : '全屏'),
                onPressed: () async {
                  context.app.toggleFullScreen();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
