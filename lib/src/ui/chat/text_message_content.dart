import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class TextMessageContent extends StatelessWidget {
  final String content;

  const TextMessageContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(content);
  }
}
