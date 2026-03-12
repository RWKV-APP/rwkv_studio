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

class _MessageThinkState extends State<MessageThink>
    with SingleTickerProviderStateMixin {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final thinkDuration = (widget.duration / 1000).toInt();
    final statusText = widget.thinking
        ? '正在思考...'
        : (thinkDuration <= 0 || thinkDuration > 180
              ? '思考完成'
              : '思考完成（用时 $thinkDuration 秒）');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _collapsed
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: widget.thinking
                ? null
                : () {
                    setState(() {
                      _collapsed = !_collapsed;
                    });
                  },
            child: MouseRegion(
              cursor: widget.thinking
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.thinking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                  if (widget.thinking) const SizedBox(width: 8),
                  Text(statusText, style: TextStyle(color: Colors.grey[100])),
                  if (!widget.thinking) const SizedBox(width: 8),
                  if (!widget.thinking)
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      turns: _collapsed ? -0.25 : 0,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: Icon(
                          FluentIcons.chevron_down_med,
                          size: 10,
                          color: Colors.grey[100],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topLeft,
            child: _collapsed
                ? const SizedBox.shrink()
                : AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    opacity: _collapsed ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey[50], width: 1),
                        ),
                      ),
                      child: TextMessageContent(
                        content: widget.content,
                        style: TextStyle(
                          color: Colors.grey[100],
                          fontSize: 14,
                          height: 1.4,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
