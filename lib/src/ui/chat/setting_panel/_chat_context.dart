part of 'chat_setting_panel.dart';

class _ChatContextSetting extends StatefulWidget {
  const _ChatContextSetting();

  @override
  State<_ChatContextSetting> createState() => _ChatContextSettingState();
}

class _ChatContextSettingState extends State<_ChatContextSetting> {
  final focusNode = FocusNode();
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: '${context.read<ChatCubit>().state.maxChatHistoryLength}',
    );
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        final state = context.read<ChatCubit>().state;
        final value = int.tryParse(controller.text.trim());
        if (value == null || value <= 0) {
          controller.text = '${state.maxChatHistoryLength}';
          return;
        }
        context.chat.setMaxChatHistoryLength(value);
        controller.text = '$value';
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .min,
      children: [
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (p, c) =>
              p.maxChatHistoryLength != c.maxChatHistoryLength,
          listener: (context, state) {
            final value = '${state.maxChatHistoryLength}';
            if (controller.text != value) {
              controller.text = value;
            }
          },
          child: const SizedBox(),
        ),
        const Text('上下文', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: Text('最大历史对话轮数')),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 60),
              child: TextBox(
                textAlign: .center,
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
