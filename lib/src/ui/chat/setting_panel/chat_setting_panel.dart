import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_form.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_preset_button.dart';

part '_system_prompt.dart';

part '_chat_context.dart';

class ChatSettingPanel extends StatelessWidget {
  const ChatSettingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .max,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const SizedBox(width: 12),
            const Expanded(child: Text('设置', style: TextStyle(fontSize: 18))),
            IconButton(
              icon: const Icon(FluentIcons.chrome_close),
              onPressed: () {
                context.chat.toggleSettingPanelVisible();
              },
            ),
            const SizedBox(width: 12),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: BlocBuilder<ChatCubit, ChatState>(
              buildWhen: (p, c) =>
                  p.selected.decodeParamId != c.selected.decodeParamId,
              builder: (context, state) {
                final currentId = state.selected.decodeParamId;
                return Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .stretch,
                  children: [
                    const _ChatContextSetting(),
                    const SizedBox(height: 22),
                    const _SystemPrompt(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '解码参数',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DecodeParamPresetButton(
                          currentId: currentId,
                          onChange: (v) {
                            context.chat.setDecodeParam(v);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<LlmCubit, LlmState>(
                      buildWhen: (p, c) => p.decodeParams != c.decodeParams,
                      builder: (context, state2) {
                        final param = state2.decodeParams[currentId];
                        return DecodeParamForm(
                          param: param ?? state2.decodeParams.values.first,
                          onChanged: state.generating
                              ? null
                              : (v) => context.llm.setOrPutDecodeParam(
                                  currentId,
                                  v,
                                ),
                        );
                      },
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
