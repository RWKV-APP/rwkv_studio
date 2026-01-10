import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/bloc_builders/rwkv_builders.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_cubit.dart';
import 'package:rwkv_studio/src/ui/widget/model_selector.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

extension _Ext on BuildContext {
  TextGenerationCubit get cubit => BlocProvider.of<TextGenerationCubit>(this);
}

class TextGenerationPage extends StatelessWidget {
  const TextGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          child: BlocBuilder<TextGenerationCubit, TextGenerationState>(
            buildWhen: (p, c) =>
                p.modelInstanceId != c.modelInstanceId ||
                p.generating != c.generating,
            builder: (context, state) {
              return Row(
                children: [
                  Text('文本生成', style: context.fluent.typography.subtitle),
                  Spacer(),
                  ModelSelector(
                    modelInstanceId: state.modelInstanceId,
                    load: true,
                    onModelSelected: (info, instance) {
                      context.cubit.selectModel(instance!.id);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    child: Row(
                      children: [
                        Icon(
                          state.generating
                              ? WindowsIcons.pause
                              : WindowsIcons.play,
                        ),
                        const SizedBox(width: 8),
                        Text(state.generating ? '停止生成' : '开始生成'),
                      ],
                    ),
                    onPressed: () {
                      if (state.generating) {
                        context.rwkv.stop(state.modelInstanceId);
                      } else {
                        context.cubit.generate(context.rwkv.generate);
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<TextGenerationCubit, TextGenerationState>(
            buildWhen: (p, c) =>
                p.controllerText != c.controllerText ||
                p.controllerScroll != c.controllerScroll ||
                p.generating != c.generating,
            builder: (context, state) {
              return TextBox(
                controller: state.controllerText,
                readOnly: state.generating,
                scrollController: state.controllerScroll,
                padding: EdgeInsetsGeometry.symmetric(horizontal: 12),
                maxLines: 100000000,
                placeholder: '请输入文本',
                foregroundDecoration: WidgetStatePropertyAll(
                  BoxDecoration(border: Border()),
                ),
                decoration: WidgetStatePropertyAll(
                  BoxDecoration(border: Border()),
                ),
              );
            },
          ),
        ),
        Divider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          color: context.fluent.cardColor,
          child: BlocBuilder<TextGenerationCubit, TextGenerationState>(
            builder: (context, state) {
              return RwkvModelStateBuilder(
                modelInstanceId: state.modelInstanceId,
                builder: (ctx, model) {
                  final decode = model.state.decodeSpeed.toStringAsFixed(2);
                  final prefill = model.state.prefillSpeed.toStringAsFixed(2);
                  final label = Text(
                    'decode: $decode t/s \t prefill: $prefill t/s',
                    textAlign: TextAlign.end,
                    style: context.fluent.typography.caption?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  );
                  if (model.state.prefillProgress < 1.0) {
                    return Row(
                      children: [
                        Spacer(),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: ProgressRing(
                            strokeWidth: 2,
                            value: model.state.prefillProgress * 100,
                          ),
                        ),
                        const SizedBox(width: 8),
                        label,
                      ],
                    );
                  }
                  return label;
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
