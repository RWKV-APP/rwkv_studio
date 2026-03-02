import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/batch_infer/batch_infer_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/batch_infer/_setting_pannel.dart';
import 'package:rwkv_studio/src/ui/batch_infer/text_painter.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/side_bar.dart';

extension _ on BuildContext {
  BatchInferCubit get cubit => BlocProvider.of<BatchInferCubit>(this);
}

class BatchInferPage extends StatelessWidget {
  const BatchInferPage._();

  static Widget create() => LayoutBuilder(
    builder: (ctx, _) {
      return KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.physicalKey == PhysicalKeyboardKey.escape) {
            ctx.app.setFullScreen(false);
          }
        },
        child: const BatchInferPage._(),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 12, vertical: 12),
      child: BlocBuilder<BatchInferCubit, BatchInferState>(
        buildWhen: (prev, cur) => cur.showSettingPanel != prev.showSettingPanel,
        builder: (context, state) {
          return CollapsibleSidebarLayout(
            open: state.showSettingPanel,
            sidebar: const BatchInferSettingPanel(),
            content: Column(
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
                              context.cubit
                                  .submit(context.rwkv)
                                  .withToast(context);
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
                Expanded(child: buildGrid()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildGrid() {
    return RepaintBoundary(
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
    );
  }
}

class _ToolBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<BatchInferCubit, BatchInferState>(
            buildWhen: (prev, cur) => cur.performance != prev.performance,
            builder: (context, state) {
              return Row(
                crossAxisAlignment: .end,
                children: [
                  Text('并行推理', style: context.fluent.typography.subtitle),
                  const SizedBox(width: 16),
                  Text(
                    '${state.performance.tps.toInt()} tokens/s',
                    style: const TextStyle(height: 2, fontSize: 10),
                  ),
                ],
              );
            },
          ),
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
                filter: (model) =>
                    model.isRemote || model.backend == ModelBackend.albatross,
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
                  if (context.cubit.state.isRunning) {
                    context.toast('请停止推理后修改');
                    return;
                  }
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
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: BlocBuilder<BatchInferCubit, BatchInferState>(
            buildWhen: (prev, cur) =>
                cur.showSettingPanel != prev.showSettingPanel,
            builder: (context, state) {
              return Button(
                child: const Text('解码参数'),
                onPressed: () async {
                  context.cubit.toggleShowSettingPanel();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
