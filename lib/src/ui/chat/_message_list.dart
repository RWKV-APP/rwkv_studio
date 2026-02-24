import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list_item.dart';
import 'package:rwkv_studio/src/widget/measure_size.dart';

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
      // logd('auto scrolling=$auto');
    }
  }

  void _onConversationChanged(ChatState state) {
    _chatScrollOffsets[chatId] = _scrollController.position.pixels;
    final list = state.messages[state.selected.id] ?? [];
    setState(() {
      chatId = state.selected.id;
      _messages = list;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _chatScrollOffsets[chatId] ??
              _scrollController.position.maxScrollExtent,
        );
      }
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
        controller: _scrollController,
        itemCount: _messages.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemBuilder: (context, i) {
          final index = i;
          final isLast = index == _messages.length - 1;
          final item = MessageListItem(
            message: _messages[index],
            isLast: isLast,
          );

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
