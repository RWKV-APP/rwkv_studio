import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_form.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_preset_button.dart';
import 'package:rwkv_studio/src/ui/common/decode_speed.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/side_bar.dart';

part '_title_bar.dart';

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
          child: BlocBuilder<TextGenerationCubit, TextGenerationState>(
            buildWhen: (p, c) => p.showSettingPane != c.showSettingPane,
            builder: (context, state) {
              return CollapsibleSidebarLayout(
                open: state.showSettingPane,
                onClose: () {
                  context.cubit.toggleSettingPane();
                },
                sidebar: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: _SettingPanel(),
                ),
                divider: const Divider(direction: .vertical),
                content: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: _TitleBar(),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Expanded(child: _TextBox()),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: BlocBuilder<TextGenerationCubit, TextGenerationState>(
            buildWhen: (p, c) => p.modelInstanceId != c.modelInstanceId,
            builder: (context, state) {
              return DecodeSpeedInfo(modelInstanceId: state.modelInstanceId);
            },
          ),
        ),
      ],
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
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 12),
          maxLines: 100000000,
          placeholder: '请输入文本',
          foregroundDecoration: const WidgetStatePropertyAll(
            BoxDecoration(border: Border(), color: Colors.transparent),
          ),
          decoration: const WidgetStatePropertyAll(
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
            const Expanded(child: Text('设置', style: TextStyle(fontSize: 18))),
            IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: () {
                context.cubit.toggleSettingPane();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: BlocBuilder<TextGenerationCubit, TextGenerationState>(
              buildWhen: (p, c) =>
                  p.decodeParamId != c.decodeParamId ||
                  p.generating != c.generating,
              builder: (context, state) {
                return Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '解码参数',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DecodeParamPresetButton(
                          currentId: state.decodeParamId,
                          onChange: (v) {
                            context.textGen.setDecodeParamId(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DecodeParamForm.createWithBloc(
                      currentId: state.decodeParamId,
                      editable: !state.generating,
                    ),
                    const SizedBox(height: 60),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
