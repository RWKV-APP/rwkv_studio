import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/bloc_builders/rwkv_builders.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_form.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';
import 'package:rwkv_studio/src/ui/generation/text_generation_cubit.dart';
import 'package:rwkv_studio/src/widget/labeled_slider.dart';

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
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: _TitleBar(),
                    ),
                    Divider(),
                    const SizedBox(height: 12),
                    Expanded(child: _TextBox()),
                  ],
                ),
              ),
              Divider(direction: Axis.vertical),
              BlocBuilder<TextGenerationCubit, TextGenerationState>(
                buildWhen: (p, c) => p.showSettingPane != c.showSettingPane,
                builder: (context, state) {
                  return AnimatedSlide(
                    offset: Offset(state.showSettingPane ? 0 : 1, 0),
                    duration: const Duration(milliseconds: 100),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: state.showSettingPane ? 240 : 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: _SettingPanel(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Divider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _PerformanceInfo(),
        ),
      ],
    );
  }
}

class _TitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextGenerationCubit, TextGenerationState>(
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
              onModelSelected: state.generating
                  ? null
                  : (info, instance) {
                      context.cubit.selectModel(instance!.id);
                    },
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state.modelInstanceId.isEmpty
                  ? null
                  : () async {
                      if (state.generating) {
                        context.rwkv.stop(state.modelInstanceId);
                      } else {
                        context.cubit.generate(context.rwkv.generate);
                      }
                    },
              child: Row(
                children: [
                  Icon(
                    state.generating ? WindowsIcons.pause : WindowsIcons.play,
                  ),
                  const SizedBox(width: 8),
                  Text(state.generating ? '停止生成' : '开始生成'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Button(
              child: Row(children: [Icon(FluentIcons.settings, size: 18)]),
              onPressed: () {
                context.cubit.toggleSettingPane();
              },
            ),
          ],
        );
      },
    );
  }
}

class _TextBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextGenerationCubit, TextGenerationState>(
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
            BoxDecoration(border: Border(), color: Colors.transparent),
          ),
          decoration: WidgetStatePropertyAll(
            BoxDecoration(border: Border(), color: Colors.transparent),
          ),
        );
      },
    );
  }
}

class _SettingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .max,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text('设置', style: context.fluent.typography.subtitle),
            ),
            IconButton(
              icon: Icon(FluentIcons.chrome_close),
              onPressed: () {
                context.cubit.toggleSettingPane();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Button(
          child: Text('重置'),
          onPressed: () {
            context.cubit.resetSettings();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                BlocBuilder<TextGenerationCubit, TextGenerationState>(
                  buildWhen: (p, c) => p.maxTokens != c.maxTokens,
                  builder: (cxt, state) {
                    return LabeledSlider(
                      title: '最大长度',
                      max: 10000,
                      min: 1,
                      value: state.maxTokens,
                      onChanged: (v) {
                        cxt.cubit.setMaxTokens(v.toInt());
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                BlocBuilder<TextGenerationCubit, TextGenerationState>(
                  buildWhen: (p, c) =>
                      p.decodeParam != c.decodeParam ||
                      p.generating != c.generating,
                  builder: (context, state) {
                    return DecodeParamForm(
                      param: state.decodeParam,
                      onChanged: state.generating
                          ? null
                          : (v) {
                              context.cubit.setDecodeParam(v);
                            },
                    );
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PerformanceInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextGenerationCubit, TextGenerationState>(
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
    );
  }
}
