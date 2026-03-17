part of '_message_input.dart';

class _McpToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) =>
          p.generationConfig.enableMcp != c.generationConfig.enableMcp,
      builder: (context, state) {
        return ToggleButton(
          checked: state.generationConfig.enableMcp,
          onChanged: (v) {
            context.chat.toggleEnableMcp();
          },
          child: const Padding(
            padding: .symmetric(horizontal: 8, vertical: 4),
            child: Text('MCP'),
          ),
        );
      },
    );
  }
}
