import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/theme/theme.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemBuilder: (context, index) {
        return _MessageItem();
      },
    );
  }
}


class _MessageItem extends StatelessWidget {


  const _MessageItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.fluent.cardColor,
      ),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text('Item'),
    );
  }
}