part of '_message_input.dart';

class _ThinkModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.generationConfig != c.generationConfig,
      builder: (context, state) {
        String label = '';
        bool checked = true;
        switch (state.generationConfig.reasoningEffort) {
          case ReasoningEffort.none:
            label = '推理-关';
            checked = false;
            break;
          case ReasoningEffort.mini:
          case ReasoningEffort.low:
            label = '推理-低';
            break;
          case ReasoningEffort.medium:
            label = '推理-中';
            break;
          case ReasoningEffort.high:
          case ReasoningEffort.xhig:
            label = '推理-高';
            break;
        }

        return AppSplitButton.toggle(
          checked: checked,
          onInvoked: () {
            context.chat.toggleReasoningEnable();
          },
          flyout: MenuFlyout(
            items: [
              MenuFlyoutItem(
                text: const Text('推理-中'),
                onPressed: () {
                  context.chat.setReasoningMode(ReasoningEffort.medium);
                },
              ),
              MenuFlyoutItem(
                text: const Text('推理-高'),
                onPressed: () {
                  context.chat.setReasoningMode(ReasoningEffort.high);
                },
              ),
            ],
          ),
          child: Padding(
            padding: const .symmetric(horizontal: 8, vertical: 4),
            child: Text(label),
          ),
        );
      },
    );
  }
}