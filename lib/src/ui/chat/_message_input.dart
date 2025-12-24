import 'package:fluent_ui/fluent_ui.dart';

class ChatMessageInput extends StatelessWidget {
  const ChatMessageInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextBox(
        placeholder: 'Type a message',
        onSubmitted: (String text) {
          print(text);
        },
        maxLines: 1000,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }
}
