import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/models/chat/message_content.dart';

import '_text_message_content.dart';

class MessageThink extends StatefulWidget {
  final MessageContent content;

  const MessageThink({super.key, required this.content});

  @override
  State<MessageThink> createState() => _MessageThinkState();
}

class _MessageThinkState extends State<MessageThink> {
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
                  if (!thinking)
                    Text(
                      statusText,
                      style: TextStyle(color: Colors.grey[100], height: 1),
                    ),
                  if (thinking)
                    _ScanningText(text: statusText, color: Colors.grey[100]),
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

class _ScanningText extends StatefulWidget {
  final String text;
  final Color color;

  const _ScanningText({required this.text, required this.color});

  @override
  State<_ScanningText> createState() => _ScanningTextState();
}

class _ScanningTextState extends State<_ScanningText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scanOffset;

  Color get _baseColor =>
      Color.lerp(widget.color, Colors.black, 0.32)?.withValues(alpha: 0.72) ??
      widget.color.withValues(alpha: 0.72);

  Color get _highlightColor =>
      Color.lerp(widget.color, Colors.white, 0.78) ?? Colors.white;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: false);
    _scanOffset = Tween<double>(
      begin: -1.15,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanOffset,
      builder: (context, child) {
        return Stack(
          children: [
            Text(widget.text, style: TextStyle(color: _baseColor, height: 1)),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _highlightColor.withValues(alpha: 0),
                    _highlightColor.withValues(alpha: 0),
                    _highlightColor.withValues(alpha: 0.28),
                    _highlightColor.withValues(alpha: 0.76),
                    _highlightColor,
                    _highlightColor,
                    _highlightColor,
                    _highlightColor.withValues(alpha: 0.76),
                    _highlightColor.withValues(alpha: 0.28),
                    _highlightColor.withValues(alpha: 0),
                    _highlightColor.withValues(alpha: 0),
                  ],
                  stops: const [
                    0,
                    0.12,
                    0.24,
                    0.36,
                    0.44,
                    0.5,
                    0.56,
                    0.64,
                    0.76,
                    0.88,
                    1,
                  ],
                  transform: _SlidingGradientTransform(
                    slidePercent: _scanOffset.value,
                  ),
                ).createShader(bounds);
              },
              child: Text(
                widget.text,
                style: TextStyle(
                  color: _highlightColor,
                  height: 1,
                  shadows: [
                    Shadow(
                      color: _highlightColor.withValues(alpha: 0.42),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.identity()
      ..translateByDouble(bounds.width * slidePercent, 0, 0, 1);
  }
}
