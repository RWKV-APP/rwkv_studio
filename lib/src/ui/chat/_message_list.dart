import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
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
    Widget content;
    if (message.error.isNotEmpty) {
      final error = Text(
        message.error,
        style: TextStyle(
          color: Colors.errorPrimaryColor,
          fontSize: 12,
          fontStyle: .italic,
        ),
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
          Scrollable.ensureVisible(
            context,
            duration: Duration(milliseconds: 200),
            alignmentPolicy: .keepVisibleAtEnd,
          );
        },
        child: content,
      );
    }

    return _MessageBox(
      alignmentEnd: message.isUser,
      footer: message.isUser
          ? null
          : _MessageItemFooter(message: message, isLast: isLast),
      child: content,
    );
  }
}

class _MessageBox extends StatelessWidget {
  final bool alignmentEnd;
  final Widget child;
  final Widget? footer;

  const _MessageBox({
    required this.alignmentEnd,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: .only(top: 16),
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: alignmentEnd ? .end : .start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: context.theme.cardColor,
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
              right: alignmentEnd ? 0 : 100,
              left: alignmentEnd ? 100 : 0,
            ),
            child: child,
          ),
          if (footer != null)
            Padding(
              padding: .symmetric(horizontal: 4, vertical: 4),
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
