import 'package:flutter/material.dart';
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
        SizedBox(width: 200, child: ChatList()),
        VerticalDivider(width: .5, thickness: .5),
        Expanded(
          child: Column(
            children: [
              ChatTitleBar(),
              Divider(height: .5, thickness: .5),
              Expanded(child: ChatMessageList()),
              Divider(height: .5, thickness: .5),
              ChatMessageInput(),
            ],
          ),
        ),
      ],
    );
  }
}
