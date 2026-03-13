import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list_item.dart';

import '_user_message.dart';

part '_empty_placeholder.dart';

class ChatMessageList extends StatefulWidget {
  final double? maxWidth;

  const ChatMessageList({super.key, this.maxWidth});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  static const double _bottomOffsetThreshold = 40;

  bool _autoScrolling = true;
  late String _chatId;
  final Map<String, double> _chatScrollOffsets = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final state = context.chat.state;
    _chatId = state.selected.id;
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

    _chatScrollOffsets[_chatId] = _scrollController.position.pixels;
    final auto = _isNearBottom();
    if (auto != _autoScrolling) {
      _autoScrolling = auto;
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) {
      return true;
    }

    final position = _scrollController.position;
    return (position.pixels - position.minScrollExtent).abs() <
        _bottomOffsetThreshold;
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
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      final target = (_chatScrollOffsets[_chatId] ?? position.minScrollExtent)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      _scrollController.jumpTo(target);
      _autoScrolling = _isNearBottom();
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
          previous.messages[previous.selected.id] !=
              current.messages[current.selected.id],
      builder: (context, state) {
        final messages = state.messages[state.selected.id] ?? [];

        return Stack(
          fit: StackFit.expand,
          children: [
            _RealList(
              messages: messages,
              maxWidth: widget.maxWidth,
              scrollController: _scrollController,
            ),
            _AnimatedEmptyPlaceholder(show: messages.isEmpty),
          ],
        );
      },
    );
  }
}

class _RealList extends StatelessWidget {
  final List<MessageModel> messages;
  final double? maxWidth;
  final ScrollController scrollController;

  const _RealList({
    required this.messages,
    required this.maxWidth,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = _resolveHorizontalPadding(constraints);
        return ListView.builder(
          controller: scrollController,
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
    );
  }

  double _resolveHorizontalPadding(BoxConstraints constraints) {
    if (maxWidth == null) {
      return 12;
    }
    if (constraints.maxWidth <= maxWidth!) {
      return 0;
    }
    return (constraints.maxWidth - maxWidth!) / 2;
  }
}
