import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list_item.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key});

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  List<MessageState> _messages = [];
  bool _autoScrolling = true;
  late String chatId = context.chat.state.selected.id;
  final Map<String, double> _chatScrollOffsets = {};

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrolling);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onConversationChanged(context.chat.state);
    });
  }

  void _onScrolling() {
    final max = _scrollController.position.maxScrollExtent;
    final auto = (max - _scrollController.position.pixels) < 40;
    if (auto != _autoScrolling) {
      _autoScrolling = auto;
      logd('auto scrolling=$auto');
    }
  }

  void _onConversationChanged(ChatState state) {
    _chatScrollOffsets[chatId] = _scrollController.position.pixels;
    final list = state.messages[state.selected.id] ?? [];
    _messages = list.reversed.toList();
    if (chatId != state.selected.id) {
      chatId = state.selected.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          // _scrollController.jumpTo(
          //   _chatScrollOffsets[chatId] ??
          //       _scrollController.position.maxScrollExtent,
          // );
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (p, c) => p.currentChat != c.currentChat,
      listener: (context, state) {
        _onConversationChanged(state);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_messages.isEmpty)
            Center(
              child: Text(
                '没有内容...',
                style: context.fluent.typography.bodyStrong,
              ),
            ),
          ListView.builder(
            controller: _scrollController,
            itemCount: _messages.length,
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemBuilder: (context, index) {
              final isLast = index == 0;
              final item = MessageListItem(
                message: _messages[index],
                isLast: isLast,
              );

              if (isLast) {
                return item;
                // return MeasureSize(
                //   onChange: (v) {
                //     if (_autoScrolling && context.chat.state.generating) {
                //       _scrollController.jumpTo(
                //         _scrollController.position.maxScrollExtent,
                //       );
                //     }
                //   },
                //   child: item,
                // );
              }

              return item;
            },
          ),
        ],
      ),
    );
  }
}
