import 'package:flutter/material.dart';

class ChatTitleBar extends StatelessWidget {
  const ChatTitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(height: 60, child: Text('Chat'));
  }
}
