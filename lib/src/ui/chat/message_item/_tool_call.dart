import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/models/chat/message_content.dart';

class MessageToolCall extends StatefulWidget {
  final MessageContent content;

  const MessageToolCall({super.key, required this.content});

  @override
  State<MessageToolCall> createState() => _MessageToolCallState();
}

class _MessageToolCallState extends State<MessageToolCall> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Padding(
          padding: _collapsed ? .zero : const .only(bottom: 6),
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
                  Text(
                    'Tool-Call ${widget.content.toolInfo.toolName}',
                    style: TextStyle(color: Colors.grey[100], height: 1),
                  ),
                  if ( widget.content.completed)
                    const SizedBox(width: 8),
                  if ( widget.content.completed)
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
                    child: Text(
                      widget.content.toolInfo.result.toString(),
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
