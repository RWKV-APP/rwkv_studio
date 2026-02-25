import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/text_message_content.dart';
import 'package:rwkv_studio/src/utils/date_utils.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class MessageListItem extends StatelessWidget {
  final MessageState message;
  final bool isLast;

  const MessageListItem({
    super.key,
    required this.message,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _ContextMenu(
        message: message,
        child: _MessageBox(
          alignmentRight: true,
          child: TextMessageContent(content: message.text),
        ),
      );
    }

    Widget content = const SizedBox();

    final response = message.bodyContent;

    if (message.error.isNotEmpty) {
      final error = SelectableText(
        "错误: ${message.error.trim()}",
        style: const TextStyle(color: Colors.errorPrimaryColor, fontSize: 12),
      );
      if (message.text.isEmpty) {
        content = error;
      } else {
        content = Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            TextMessageContent(content: response),
            error,
          ],
        );
      }
    } else {
      if (response.isEmpty && message.stopped && !message.paused) {
        content = const Text(
          '模型没有生成任何内容...',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 12,
            color: Colors.errorPrimaryColor,
          ),
        );
      } else if (response.isNotEmpty) {
        content = TextMessageContent(content: response);
      }
    }

    final prefilling =
        !message.hasThinkContent &&
        message.bodyContent.isEmpty &&
        !message.stopped;

    Widget box = _MessageBox(
      alignmentRight: message.isUser,
      footer: message.isUser
          ? null
          : _MessageItemFooter(message: message, isLast: isLast),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          if (prefilling)
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
              paused: message.stopReason == StopReason.canceled,
            ),
          if (message.hasThinkContent && response.isNotEmpty)
            const SizedBox(height: 6),
          content,
        ],
      ),
    );

    box = _ContextMenu(message: message, child: box);
    return box;
  }
}

class _MessageBox extends StatelessWidget {
  final bool alignmentRight;
  final Widget child;
  final Widget? footer;

  const _MessageBox({
    required this.alignmentRight,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const .only(top: 16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: alignmentRight ? .end : .start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  offset: const Offset(1, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const .symmetric(horizontal: 12, vertical: 12),
            margin: .only(
              right: alignmentRight ? 0 : 100,
              left: alignmentRight ? 100 : 0,
            ),
            child: child,
          ),
          if (footer != null)
            Padding(
              padding: const .symmetric(horizontal: 4, vertical: 4),
              child: footer,
            ),
        ],
      ),
    );
  }
}

class _MessageItemFooter extends StatelessWidget {
  final MessageState message;
  final bool isLast;

  const _MessageItemFooter({required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final eos = message.stopReason == StopReason.eos;
    final paused = message.stopReason == StopReason.canceled;
    final generating = !message.stopped;
    final completed = !{
      StopReason.none,
      StopReason.canceled,
    }.contains(message.stopReason);

    return Row(
      children: [
        if (isLast && paused)
          IconButton(
            icon: const Icon(WindowsIcons.play),
            onPressed: () {
              context.chat.resume(context.rwkv).withToast(context);
            },
          ),
        if (isLast && !generating)
          IconButton(
            icon: const Icon(WindowsIcons.refresh),
            onPressed: () {
              context.chat.regenerate(context.rwkv).withToast(context);
            },
          ),
        if (isLast && !generating) const SizedBox(width: 4),
        Text(
          message.modelName,
          style: TextStyle(fontSize: 10, color: Colors.grey[80]),
        ),
        if (eos) const SizedBox(width: 4),
        if (eos)
          Text('· EOS', style: TextStyle(fontSize: 10, color: Colors.grey[80])),
        if (completed) const SizedBox(width: 4),
        if (completed)
          Text(
            '· ${message.updateAt.difference(message.createAt).displayDuration}',
            style: TextStyle(fontSize: 10, color: Colors.grey[80]),
          ),
        if (completed && message.tokenCount > 0) const SizedBox(width: 4),
        if (completed && message.tokenCount > 0)
          Text(
            '· ${message.tokenCount} tokens',
            style: TextStyle(fontSize: 10, color: Colors.grey[80]),
          ),
      ],
    );
  }
}

class _ContextMenu extends StatelessWidget {
  final Widget child;
  final MessageState message;
  final _contextController = FlyoutController();

  _ContextMenu({required this.child, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showMenu(context, details, message);
      },
      child: FlyoutTarget(controller: _contextController, child: child),
    );
  }

  void _onEditTap() async {
    _contextController.close();
    await Future.delayed(const Duration(milliseconds: 100));
    final controller = TextEditingController(text: message.text);
    _contextController.showFlyout<void>(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.topCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (context) {
        return FlyoutContent(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('编辑内容'),
              const SizedBox(height: 12.0),
              Flexible(
                child: TextBox(
                  controller: controller,
                  maxLines: 10000,
                  minLines: 3,
                  placeholder: '请输入内容',
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  const Spacer(),
                  Button(
                    child: const Text('取消'),
                    onPressed: () {
                      _contextController.close();
                    },
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    child: const Text('确定'),
                    onPressed: () {
                      final v = controller.text.trim();
                      if (v.isEmpty) {
                        context.toast('内容不能为空');
                      } else {
                        context.chat
                            .updateMessageContent(message.id, v)
                            .withToast(context);
                        _contextController.close();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMenu(BuildContext ctx, TapUpDetails d, MessageState message) {
    final box = ctx.findRenderObject() as RenderBox;
    final position = box.localToGlobal(
      d.localPosition,
      ancestor: Navigator.of(ctx).context.findRenderObject(),
    );
    _contextController.showFlyout<void>(
      barrierColor: Colors.black.withValues(alpha: 0.1),
      position: position,
      builder: (context) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              leading: const WindowsIcon(WindowsIcons.copy),
              text: const Text('复制'),
              onPressed: () async {
                Clipboard.setData(ClipboardData(text: message.text));
              },
            ),
            MenuFlyoutItem(
              leading: const WindowsIcon(WindowsIcons.edit),
              text: const Text('编辑'),
              onPressed: _onEditTap,
            ),
            MenuFlyoutItem(
              leading: const WindowsIcon(
                WindowsIcons.delete,
                color: Colors.errorPrimaryColor,
              ),
              text: const Text(
                '删除',
                style: TextStyle(color: Colors.errorPrimaryColor),
              ),
              onPressed: () async {
                context.chat.deleteMessage(message.id).withToast(context);
              },
            ),
          ],
        );
      },
    );
  }
}
