import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class TextMessageContent extends StatelessWidget {
  final String content;

  const TextMessageContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      content,
      style: TextStyle(height: 1.6, letterSpacing: 0.6),
    );
  }
}

class MessageThink extends StatefulWidget {
  final String content;

  const MessageThink({super.key, required this.content});

  @override
  State<MessageThink> createState() => _MessageThinkState();
}

class _MessageThinkState extends State<MessageThink> {
  bool collapse = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: .only(left: 10),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: Colors.grey[50], width: 1)),
          ),
          child: GptMarkdown(
            widget.content,
            style: TextStyle(
              color: Colors.grey[100],
              fontSize: 14,
              height: 1.6,
              letterSpacing: 0.6,
            ),
          ),
        )
      ],
    );
  }
}
