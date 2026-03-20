part of 'chat_setting_panel.dart';

class _SystemPrompt extends StatefulWidget {
  const _SystemPrompt();

  @override
  State<_SystemPrompt> createState() => _SystemPromptState();
}

class _SystemPromptState extends State<_SystemPrompt> {
  final focusNode = FocusNode();
  late final controller = TextEditingController();

  @override
  void initState() {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        context.chat.setSystemPrompt(controller.text.trim());
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorBg = context.fluent.activeColor;
    final colorAccent = context.fluent.selectionColor;
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .max,
      children: [
        BlocListener<ChatCubit, ChatState>(
          listenWhen: (p, c) =>
              p.generationConfig != c.generationConfig ||
              p.selected != c.selected,
          listener: (context, state) {
            final g = state.selected.useGlobalSystemPrompt;
            final prompt = g
                ? state.generationConfig.prompt
                : state.selected.systemPrompt;
            if (prompt != controller.text) {
              controller.text = prompt;
            }
          },
          child: const SizedBox(),
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                '系统提示词',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: context.fluent.cardColor,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey[60], width: .5),
              ),
              clipBehavior: .antiAlias,
              child: BlocBuilder<ChatCubit, ChatState>(
                buildWhen: (p, c) => p.selected != c.selected,
                builder: (context, state) {
                  final global = state.selected.useGlobalSystemPrompt;
                  return Row(
                    children: [
                      GestureDetector(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: global
                                ? colorAccent
                                : context.fluent.cardColor,
                          ),
                          padding: const .symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            '全局',
                            style: TextStyle(
                              color: global ? colorBg : null,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                        ),
                        onTap: () {
                          context.chat.setUseGlobalSystemPrompt(true);
                        },
                      ),
                      GestureDetector(
                        child: Container(
                          padding: const .symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: global
                                ? context.fluent.cardColor
                                : colorAccent,
                          ),
                          child: Text(
                            '对话',
                            style: TextStyle(
                              color: global ? null : colorBg,
                              fontSize: 12,
                              height: 1,
                            ),
                          ),
                        ),
                        onTap: () {
                          context.chat.setUseGlobalSystemPrompt(false);
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextBox(
          minLines: 3,
          maxLines: 100,
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
