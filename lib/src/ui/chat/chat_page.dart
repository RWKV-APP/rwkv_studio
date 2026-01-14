import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/global/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/_chat_list.dart';
import 'package:rwkv_studio/src/ui/chat/_message_input.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list.dart';
import 'package:rwkv_studio/src/ui/chat/_title_bar.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('对话')),
                    IconButton(
                      icon: const Icon(FluentIcons.add),
                      onPressed: () {
                        context.chat.newChat();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: ChatList()),
            ],
          ),
        ),
        Divider(direction: .vertical),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChatTitleBar(),
              Divider(),
              Expanded(child: ChatMessageList()),
              Divider(),
              ChatMessageInput(),
            ],
          ),
        ),
      ],
    );
  }
}
