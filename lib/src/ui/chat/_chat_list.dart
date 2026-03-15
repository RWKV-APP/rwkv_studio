import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/utils/date_utils.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  static const Duration _itemAnimationDuration = Duration(milliseconds: 220);

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<ConversationModel> _conversations = <ConversationModel>[];
  bool _animateListChanges = false;

  @override
  void initState() {
    super.initState();
    _conversations.addAll(context.chat.state.conversations);
    _animateListChanges = _conversations.isNotEmpty;
  }

  void _syncConversations(List<ConversationModel> next) {
    final listState = _listKey.currentState;
    final duration = _animateListChanges
        ? _itemAnimationDuration
        : Duration.zero;
    _animateListChanges = true;

    final nextIds = next.map((e) => e.id).toSet();
    for (var index = _conversations.length - 1; index >= 0; index--) {
      final conversation = _conversations[index];
      if (nextIds.contains(conversation.id)) {
        continue;
      }

      final removed = _conversations.removeAt(index);
      listState?.removeItem(
        index,
        (context, animation) => _AnimatedConversationListEntry(
          animation: animation,
          child: _Item(
            key: ValueKey<String>('conversation-${removed.id}'),
            conversation: removed,
          ),
        ),
        duration: duration,
      );
    }

    for (var targetIndex = 0; targetIndex < next.length; targetIndex++) {
      final nextConversation = next[targetIndex];
      final currentIndex = _conversations.indexWhere(
        (e) => e.id == nextConversation.id,
      );

      if (currentIndex == -1) {
        _conversations.insert(targetIndex, nextConversation);
        listState?.insertItem(targetIndex, duration: duration);
        continue;
      }

      if (currentIndex != targetIndex) {
        _conversations.removeAt(currentIndex);
        _conversations.insert(targetIndex, nextConversation);
        continue;
      }

      _conversations[targetIndex] = nextConversation;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (previous, current) =>
          previous.conversations != current.conversations,
      listener: (context, state) => _syncConversations(state.conversations),
      child: AnimatedList(
        key: _listKey,
        initialItemCount: _conversations.length,
        itemBuilder: (context, index, animation) {
          return _AnimatedConversationListEntry(
            animation: animation,
            child: _Item(
              key: ValueKey<String>('conversation-${_conversations[index].id}'),
              conversation: _conversations[index],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedConversationListEntry extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedConversationListEntry({
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SizeTransition(
        sizeFactor: curved,
        axisAlignment: -1,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final ConversationModel conversation;

  const _Item({super.key, required this.conversation});

  void _onSelect(BuildContext context, ConversationModel conversation) async {
    await context.chat.mayPause(context.rwkv);
    if (context.mounted) context.chat.selectConversation(conversation);
  }

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
              selected: conversation.id == state.selected.id,
              leading: Container(
                decoration: BoxDecoration(
                  color: context.fluent.accentColor.lightest,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const .all(6),
                child: Icon(
                  WindowsIcons.message,
                  color: context.fluent.activeColor,
                  size: 14,
                ),
              ),
              title: Padding(
                padding: const .only(top: 6, bottom: 6, right: 12),
                child: Text(
                  conversation.title.isEmpty ? 'untitled' : conversation.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              trailing: Text(
                conversation.updateAt.prettyDataTime,
                style: context.fluent.typography.caption,
              ),
              onSelectionChange: (selected) {
                if (selected) {
                  _onSelect(context, conversation);
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
  ConversationModel conversation,
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
            leading: const WindowsIcon(
              WindowsIcons.delete,
              color: Colors.errorPrimaryColor,
            ),
            text: const Text(
              '删除',
              style: TextStyle(color: Colors.errorPrimaryColor),
            ),
            onPressed: () async {
              await context.chat.mayPause(context.rwkv);
              if (!ctx.mounted) return;
              await ctx.chat.deleteConversation(conversation.id).withToast(ctx);
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
