import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/_message_context_menu.dart';

class UserMessageItem extends StatelessWidget {
  final MessageModel message;

  const UserMessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: .centerRight,
      child: MessageContextMenu(
        message: message,
        child: Container(
          padding: const .symmetric(horizontal: 16, vertical: 12),
          margin: const .only(right: 16),
          decoration: BoxDecoration(
            color: context.fluent.cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                offset: const Offset(1, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(message.text),
        ),
      ),
    );
  }
}
