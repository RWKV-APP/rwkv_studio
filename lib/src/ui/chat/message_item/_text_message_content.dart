import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/widget/markdown.dart';

class TextMessageContent extends StatelessWidget {
  final String content;
  final TextStyle? style;

  static const TextStyle _defaultStyle = TextStyle(
    fontSize: 14,
    height: 1.6,
    letterSpacing: 0.6,
  );

  const TextMessageContent({super.key, required this.content, this.style});

  @override
  Widget build(BuildContext context) {
    return Markdown(text: content, style: style ?? _defaultStyle);
  }
}
