import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Text('Message $index');
      },
    );
  }
}
