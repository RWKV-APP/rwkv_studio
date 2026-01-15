import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/global/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/measure_size.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.messages[p.selected] != c.messages[c.selected],
      builder: (context, state) {
        final list = state.messages[state.selected] ?? [];
        return ListView.builder(
          itemCount: list.length,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemBuilder: (context, index) {
            return _MessageItem(
              message: list[index],
              isLast: index == list.length - 1,
            );
          },
        );
      },
    );
  }
}

class _MessageItem extends StatelessWidget {
  final MessageState message;
  final bool isLast;

  const _MessageItem({required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final theme = context.fluent;

    Widget content;
    if (message.error.isNotEmpty) {
      final error = Text(
        message.error,
        style: TextStyle(color: Colors.errorPrimaryColor, fontSize: 12),
      );
      if (message.text.isEmpty) {
        content = error;
      } else {
        content = Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [Text(message.text), error],
        );
      }
    } else {
      content = SelectableText(
        message.text,
        style: TextStyle(height: 1.4, letterSpacing: 1),
      );
    }

    if (isLast) {
      content = MeasureSize(
        onChange: (s) {
          Scrollable.ensureVisible(context);
        },
        child: content,
      );
    }

    return Container(
      width: double.infinity,
      margin: .only(top: 16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: message.isUser ? .end : .start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  offset: Offset(1, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: .symmetric(horizontal: 12, vertical: 12),
            margin: .only(
              right: message.isUser ? 0 : 100,
              left: message.isUser ? 100 : 0,
            ),
            child: content,
          ),
          if (!message.isUser && message.modelName.isNotEmpty)
            Padding(
              padding: .symmetric(horizontal: 4, vertical: 4),
              child: _MessageItemFooter(message: message, isLast: isLast),
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

    return Row(
      children: [
        if (isLast && paused)
          IconButton(
            icon: Icon(WindowsIcons.play),
            onPressed: () {
              context.chat.resume(context.rwkv).withToast(context);
            },
          ),
        if (isLast)
          IconButton(
            icon: Icon(WindowsIcons.refresh),
            onPressed: () {
              context.chat.regenerate(context.rwkv).withToast(context);
            },
          ),
        if (isLast) const SizedBox(width: 4),
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
