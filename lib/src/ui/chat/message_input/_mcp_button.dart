part of '_message_input.dart';

class _McpToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) =>
          p.generationConfig.enableMcp != c.generationConfig.enableMcp ||
          p.supportMCP != c.supportMCP,
      builder: (context, state) {
        final supported = context.chat.state.supportMCP;

        return Tooltip(
          message: supported ? 'MCP' : 'RWKV does not support MCP yet.',
          child: ToggleButton(
            checked: state.generationConfig.enableMcp,
            onChanged: !supported
                ? null
                : (v) {
                    context.chat.toggleEnableMcp();
                  },
            child: const Padding(
              padding: .symmetric(horizontal: 8, vertical: 4),
              child: Text('MCP'),
            ),
          ),
        );
      },
    );
  }
}
