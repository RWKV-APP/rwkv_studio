import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/_message_context_menu.dart';
import 'package:rwkv_studio/src/ui/chat/_text_message_content.dart';
import 'package:rwkv_studio/src/utils/date_utils.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class LastAssistantMessageItem extends StatefulWidget {
  final MessageModel message;

  const LastAssistantMessageItem({super.key, required this.message});

  @override
  State<LastAssistantMessageItem> createState() =>
      _LastAssistantMessageItemState();
}

class _LastAssistantMessageItemState extends State<LastAssistantMessageItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _appearController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _appearController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(
        CurvedAnimation(parent: _appearController, curve: Curves.easeOutCubic),
      );

  late Widget _cachedBox;

  @override
  void initState() {
    super.initState();
    _cachedBox = _buildBox();
  }

  @override
  void didUpdateWidget(covariant LastAssistantMessageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.message, widget.message)) {
      _cachedBox = _buildBox();
    }
  }

  Widget _buildBox() {
    return MessageContextMenu(
      message: widget.message,
      child: RepaintBoundary(
        child: _AssistantMessageBubble(
          message: widget.message,
          footer: _AnimatedAssistantFooter(message: widget.message),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: _cachedBox),
    );
  }
}

class HistoryAssistantMessageItem extends StatelessWidget {
  final MessageModel message;

  const HistoryAssistantMessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MessageContextMenu(
      message: message,
      child: RepaintBoundary(
        child: _AssistantMessageBubble(
          message: message,
          footer: _HistoryAssistantFooter(message: message),
        ),
      ),
    );
  }
}

class _AssistantMessageBubble extends StatelessWidget {
  final MessageModel message;
  final Widget? footer;

  const _AssistantMessageBubble({required this.message, required this.footer});

  @override
  Widget build(BuildContext context) {
    final response = message.bodyContent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.only(left: 12, top: 16),
          margin: const EdgeInsets.only(right: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.waitingForResponse)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: ProgressRing(strokeWidth: 3),
                ),
              if (message.hasThinkContent)
                MessageThink(
                  content: message.thinkContent,
                  thinking: message.thinking,
                  duration: message.thinkEndTime - message.firstTokenTime,
                  paused: message.paused,
                ),
              if (message.hasThinkContent && response.isNotEmpty)
                const SizedBox(height: 6),
              _AssistantMessageContent(message: message, response: response),
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: footer,
          ),
      ],
    );
  }
}

class _AssistantMessageContent extends StatelessWidget {
  final MessageModel message;
  final String response;

  const _AssistantMessageContent({
    required this.message,
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    if (message.error.isNotEmpty) {
      final error = SelectableText(
        '错误: ${message.error.trim()}',
        style: const TextStyle(color: Colors.errorPrimaryColor, fontSize: 12),
      );

      if (message.text.isEmpty) {
        return _ErrorMessageBox(child: error);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (response.isNotEmpty) TextMessageContent(content: response),
          error,
        ],
      );
    }

    if (response.isEmpty && message.stopped && !message.paused) {
      return const _ErrorMessageBox(
        child: Text(
          '模型没有生成任何内容...',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: Colors.errorPrimaryColor,
          ),
        ),
      );
    }

    if (response.isEmpty) {
      return const SizedBox.shrink();
    }

    return TextMessageContent(content: response);
  }
}

class _ErrorMessageBox extends StatelessWidget {
  final Widget child;

  const _ErrorMessageBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.errorPrimaryColor.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.error, color: Colors.errorPrimaryColor),
          const SizedBox(width: 8),
          Flexible(child: child),
        ],
      ),
    );
  }
}

class _AnimatedAssistantFooter extends StatelessWidget {
  final MessageModel message;

  const _AnimatedAssistantFooter({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _LastAssistantFooter(
        key: ValueKey<String>(
          'last-footer-${message.id}-${message.stopReason.name}',
        ),
        message: message,
      ),
    );
  }
}

class _LastAssistantFooter extends StatelessWidget {
  final MessageModel message;

  const _LastAssistantFooter({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final paused = message.stopReason == StopReason.canceled;
    final generating = !message.stopped;

    return Row(
      children: [
        if (paused)
          IconButton(
            icon: const Icon(WindowsIcons.play),
            onPressed: () async {
              await context.chat.resume(context.rwkv).withToast(context);
            },
          ),
        if (!generating)
          IconButton(
            icon: const Icon(WindowsIcons.refresh),
            onPressed: () async {
              await context.chat.regenerate(context.rwkv).withToast(context);
            },
          ),
        if (!generating) const SizedBox(width: 4),
        _AssistantMetaText(message: message, leadingSpacing: false),
      ],
    );
  }
}

class _HistoryAssistantFooter extends StatelessWidget {
  final MessageModel message;

  const _HistoryAssistantFooter({required this.message});

  @override
  Widget build(BuildContext context) {
    return _AssistantMetaText(message: message);
  }
}

class _AssistantMetaText extends StatelessWidget {
  final MessageModel message;
  final bool leadingSpacing;

  const _AssistantMetaText({required this.message, this.leadingSpacing = true});

  @override
  Widget build(BuildContext context) {
    final metaStyle = TextStyle(fontSize: 10, color: Colors.grey[80]);
    final completed = !{
      StopReason.none,
      StopReason.canceled,
    }.contains(message.stopReason);

    final items = <Widget>[
      if (leadingSpacing) const SizedBox(width: 8),
      Text(message.modelName, style: metaStyle),
      if (message.stopReason == StopReason.eos) ...[
        const SizedBox(width: 4),
        Text('· EOS', style: metaStyle),
      ],
      if (completed) ...[
        const SizedBox(width: 4),
        Text(
          '· ${message.updateAt.difference(message.createAt).displayDuration}',
          style: metaStyle,
        ),
      ],
      if (completed && message.tokenCount > 0) ...[
        const SizedBox(width: 4),
        Text('· ${message.tokenCount} tokens', style: metaStyle),
      ],
    ];

    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }
}
