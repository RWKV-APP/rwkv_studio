import 'package:flutter/material.dart';

class ChatTitleBar extends StatelessWidget {
  const ChatTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      child: Text('Chat'),
      alignment: Alignment.centerLeft,
    );
  }
}
