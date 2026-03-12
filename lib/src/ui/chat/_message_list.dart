import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list_item.dart';

import '_user_message.dart';

class ChatMessageList extends StatefulWidget {
  final double? maxWidth;

  const ChatMessageList({super.key, this.maxWidth});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  bool _autoScrolling = true;
  late String _chatId = context.chat.state.selected.id;
  final Map<String, double> _chatScrollOffsets = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrolling);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScrolling)
      ..dispose();
    super.dispose();
  }

  void _onScrolling() {
    if (!_scrollController.hasClients) {
      return;
    }

    final max = _scrollController.position.maxScrollExtent;
    final auto = (max - _scrollController.position.pixels) < 40;
    if (auto != _autoScrolling) {
      _autoScrolling = auto;
    }
  }

  void _onConversationChanged(ChatState state) {
    if (_chatId == state.selected.id) {
      return;
    }

    if (_scrollController.hasClients) {
      _chatScrollOffsets[_chatId] = _scrollController.position.pixels;
    }

    _chatId = state.selected.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.jumpTo(
        _chatScrollOffsets[_chatId] ??
            _scrollController.position.minScrollExtent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.selected.id != current.selected.id,
      listener: (context, state) {
        _onConversationChanged(state);
      },
      buildWhen: (previous, current) =>
          previous.selected.id != current.selected.id ||
          previous.currentChat != current.currentChat,
      builder: (context, state) {
        final messages = state.currentChat;

        return Stack(
          fit: StackFit.expand,
          children: [
            if (messages.isEmpty)
              Center(
                child: Text(
                  '没有内容...',
                  style: context.fluent.typography.bodyStrong,
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = _resolveHorizontalPadding(
                  constraints,
                );

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  reverse: true,
                  cacheExtent: 1200,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 12,
                  ),
                  itemBuilder: (context, index) {
                    final reversedIndex = messages.length - 1 - index;
                    final message = messages[reversedIndex];

                    if (message.isUser) {
                      return UserMessageItem(
                        key: ValueKey<String>(message.id),
                        message: message,
                      );
                    }

                    if (index == 0) {
                      return LastAssistantMessageItem(
                        key: ValueKey<String>(message.id),
                        message: message,
                      );
                    }

                    return HistoryAssistantMessageItem(
                      key: ValueKey<String>(message.id),
                      message: message,
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  double _resolveHorizontalPadding(BoxConstraints constraints) {
    if (widget.maxWidth == null) {
      return 12;
    }
    if (constraints.maxWidth <= widget.maxWidth!) {
      return 0;
    }
    return (constraints.maxWidth - widget.maxWidth!) / 2;
  }
}
