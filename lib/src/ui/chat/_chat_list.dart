import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/date_utils.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.conversations != c.conversations,
      builder: (context, state) {
        return ListView.builder(
          itemCount: state.conversations.length,
          itemBuilder: (context, index) {
            return PointerInterceptor(
              child: _Item(conversation: state.conversations[index]),
            );
          },
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  final ConversationState conversation;

  const _Item({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.selected != c.selected,
      builder: (context, state) {
        return GestureDetector(
          onSecondaryTapUp: (details) {
            _showMenu(context, details, conversation);
          },
          child: FlyoutTarget(
            controller: _contextController,
            child: ListTile.selectable(
              selected: conversation.id == state.selected,
              leading: Container(
                decoration: BoxDecoration(
                  color: context.fluent.accentColor.lightest,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(6),
                child: Icon(
                  WindowsIcons.message,
                  color: context.fluent.activeColor,
                  size: 14,
                ),
              ),
              title: Padding(
                padding: .only(top: 8, bottom: 8, right: 12),
                child: Text(
                  conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13),
                ),
              ),
              trailing: Text(
                conversation.updateAt.displayTime,
                style: context.fluent.typography.caption,
              ),
              onSelectionChange: (selected) {
                if (selected) {
                  context.chat.selectConversation(conversation.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

final _contextController = FlyoutController();

void _showMenu(
  BuildContext ctx,
  TapUpDetails d,
  ConversationState conversation,
) {
  final box = ctx.findRenderObject() as RenderBox;
  final position = box.localToGlobal(
    d.localPosition,
    ancestor: Navigator.of(ctx).context.findRenderObject(),
  );
  _contextController.showFlyout<void>(
    barrierColor: Colors.black.withValues(alpha: 0.1),
    position: position,
    builder: (context) {
      return MenuFlyout(
        items: [
          MenuFlyoutItem(
            leading: WindowsIcon(
              WindowsIcons.delete,
              color: Colors.errorPrimaryColor,
            ),
            text: Text('删除', style: TextStyle(color: Colors.errorPrimaryColor)),
            onPressed: () {
              context.chat.deleteConversation(conversation.id).withToast(ctx);
              Flyout.of(context).close();
            },
          ),
          MenuFlyoutItem(
            leading: const WindowsIcon(WindowsIcons.share),
            text: const Text('导出历史'),
            onPressed: null,
          ),
        ],
      );
    },
  );
}
