import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/models/chat/message_content.dart';

import '_text_message_content.dart';

class MessageThink extends StatefulWidget {
  final MessageContent content;

  const MessageThink({super.key, required this.content});

  @override
  State<MessageThink> createState() => _MessageThinkState();
}

class _MessageThinkState extends State<MessageThink>
    with SingleTickerProviderStateMixin {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final duration = widget.content.duration;
    final thinking = !widget.content.completed;

    final thinkDuration = duration.inSeconds;
    final statusText = thinking
        ? '正在思考...'
        : (thinkDuration <= 0 || thinkDuration > 180
              ? '思考完成'
              : '思考完成（用时 $thinkDuration 秒）');

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Padding(
          padding: _collapsed ? .zero : const .only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _collapsed = !_collapsed;
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: .center,
                children: [
                  if (thinking)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                  if (thinking) const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(color: Colors.grey[100], height: 1),
                  ),
                  const SizedBox(width: 8),
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
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: _collapsed
              ? const SizedBox.shrink()
              : AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _collapsed ? 0 : 1,
                  child: Container(
                    padding: const .only(left: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey[50], width: 1),
                      ),
                    ),
                    child: TextMessageContent(
                      content: widget.content.text,
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
      ],
    );
  }
}
