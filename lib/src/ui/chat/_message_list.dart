import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/text_message_content.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/measure_size.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final _scrollController = ScrollController();
  String chatId = '';
  List<MessageState> _messages = [];
  bool _autoScrolling = true;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final max = _scrollController.position.maxScrollExtent;
      final auto = (max - _scrollController.position.pixels) < 40;
      if (auto != _autoScrolling) {
        _autoScrolling = auto;
        logd('auto scrolling=$auto');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onConversationChanged(context.chat.state);
    });
  }

  void _onConversationChanged(ChatState state) {
    final list = state.messages[state.selected.id] ?? [];
    setState(() {
      chatId = state.selected.id;
      _messages = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (p, c) => p.currentChat != c.currentChat,
      listener: (context, state) {
        _onConversationChanged(state);
      },
      child: ListView.builder(
        key: PageStorageKey('message-$chatId'),
        controller: _scrollController,
        itemCount: _messages.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemBuilder: (context, i) {
          final index = i;
          final isLast = index == _messages.length - 1;
          final item = _MessageItem(message: _messages[index], isLast: isLast);

          if (isLast) {
            return MeasureSize(
              onChange: (v) {
                if (_autoScrolling && context.chat.state.generating) {
                  Scrollable.ensureVisible(
                    context,
                    duration: const Duration(milliseconds: 200),
                    alignmentPolicy: .keepVisibleAtEnd,
                  );
                }
              },
              child: item,
            );
          }

          return item;
        },
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final MessageState message;
  final bool isLast;

  const _MessageItem({required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    Widget content;

    final response = message.bodyContent;
    if (message.error.isNotEmpty) {
      final error = SelectableText(
        message.error.trim(),
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
      content = TextMessageContent(content: response);
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
          if (response.isNotEmpty || message.error.isNotEmpty) content,
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
    final generating = message.stopReason == StopReason.none;

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
          Text('EOS', style: TextStyle(fontSize: 10, color: Colors.grey[80])),
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
                logd(message.text);
                Clipboard.setData(ClipboardData(text: message.text));
              },
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
                //
              },
            ),
          ],
        );
      },
    );
  }
}
