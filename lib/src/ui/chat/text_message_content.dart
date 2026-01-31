import 'package:fluent_ui/fluent_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

class TextMessageContent extends StatelessWidget {
  final String content;

  const TextMessageContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return GptMarkdown(
      content,
      style: const TextStyle(height: 1.6, letterSpacing: 0.6),
    );
  }
}

class MessageThink extends StatefulWidget {
  final String content;
  final bool thinking;
  final int duration;
  final bool paused;

  const MessageThink({
    super.key,
    required this.content,
    required this.thinking,
    required this.duration,
    required this.paused,
  });

  @override
  State<MessageThink> createState() => _MessageThinkState();
}

class _MessageThinkState extends State<MessageThink> {
  bool collapse = false;

  @override
  Widget build(BuildContext context) {
    final thinkDuration = (widget.duration / 1000).toInt();

    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: collapse ? .zero : const .only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                collapse = !collapse;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  if (widget.thinking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                  if (widget.thinking) const SizedBox(width: 8),
                  Text(
                    widget.thinking ? '正在思考...' : '思考完成 (用时 $thinkDuration 秒)',
                    style: TextStyle(color: Colors.grey[100]),
                  ),
                  if (!widget.thinking) const SizedBox(width: 8),
                  if (!widget.thinking)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: Icon(
                        collapse
                            ? FluentIcons.chevron_right_med
                            : FluentIcons.chevron_down_med,
                        size: 10,
                        color: Colors.grey[100],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: collapse ? 0 : null,
          child: Container(
            padding: const .only(left: 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[50], width: 1),
              ),
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
          ),
        ),
      ],
    );
  }
}
