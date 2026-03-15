import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class MessageContextMenu extends StatefulWidget {
  final Widget child;
  final MessageModel message;

  const MessageContextMenu({
    super.key,
    required this.child,
    required this.message,
  });

  @override
  State<MessageContextMenu> createState() => _MessageContextMenuState();
}

class _MessageContextMenuState extends State<MessageContextMenu> {
  final FlyoutController _contextController = FlyoutController();

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details) {
        _showMenu(context, details);
      },
      child: FlyoutTarget(controller: _contextController, child: widget.child),
    );
  }

  Future<void> _openEditFlyout() async {
    _contextController.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }

    _contextController.showFlyout<void>(
      autoModeConfiguration: widget.message.text.length > 400
          ? FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.full)
          : null,
      placementMode: FlyoutPlacementMode.auto,
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (context) {
        return _EditMessageFlyout(
          initialValue: widget.message.text,
          onCancel: _contextController.close,
          onSubmit: (value) async {
            await context.chat
                .updateMessageContent(widget.message.id, value)
                .withToast(context);
          },
        );
      },
    );
  }

  void _showMenu(BuildContext context, TapUpDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(
      details.localPosition,
      ancestor: Navigator.of(context).context.findRenderObject(),
    );

    _contextController.showFlyout<void>(
      barrierColor: Colors.black.withValues(alpha: 0.1),
      position: position,
      builder: (menuContext) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              leading: const WindowsIcon(WindowsIcons.copy),
              text: const Text('复制'),
              onPressed: () async {
                final text = widget.message.isUser
                    ? widget.message.text
                    : widget.message.bodyContent;
                await Clipboard.setData(ClipboardData(text: text));
              },
            ),
            MenuFlyoutItem(
              leading: const WindowsIcon(WindowsIcons.edit),
              text: const Text('编辑'),
              onPressed: _openEditFlyout,
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
                await menuContext.chat
                    .deleteMessage(widget.message.id)
                    .withToast(menuContext);
              },
            ),
          ],
        );
      },
    );
  }
}

class _EditMessageFlyout extends StatefulWidget {
  final String initialValue;
  final VoidCallback onCancel;
  final Future<void> Function(String value) onSubmit;

  const _EditMessageFlyout({
    required this.initialValue,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_EditMessageFlyout> createState() => _EditMessageFlyoutState();
}

class _EditMessageFlyoutState extends State<_EditMessageFlyout> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlyoutContent(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('编辑内容'),
          const SizedBox(height: 12),
          Flexible(
            child: TextBox(
              controller: _controller,
              maxLines: 10000,
              minLines: 3,
              placeholder: '请输入内容',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Button(onPressed: widget.onCancel, child: const Text('取消')),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: () async {
                  final value = _controller.text.trim();
                  if (value.isEmpty) {
                    context.toast('内容不能为空');
                    return;
                  }
                  await widget.onSubmit(value);
                  if (mounted) {
                    widget.onCancel();
                  }
                },
                child: const Text('确定'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
