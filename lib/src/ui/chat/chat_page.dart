import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/chat/_chat_list.dart';
import 'package:rwkv_studio/src/ui/chat/message_input/_message_input.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list.dart';
import 'package:rwkv_studio/src/ui/chat/_title_bar.dart';
import 'package:rwkv_studio/src/widget/resizable_split_layout.dart';
import 'package:rwkv_studio/src/widget/side_bar.dart';

import '_chat_setting_panel.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.showConversationList != c.showConversationList,
      builder: (context, state) {
        return ResizableSplitLayout(
          restoreId: 'split-conv',
          fixed: const _ConversationList(),
          flexible: const _Chat(),
          direction: .horizontal,
          hideFixedWidget: !state.showConversationList,
          size: 300,
          minSize: 150,
          maxSize: 500,
        );
      },
    );
  }
}

class _ConversationList extends StatefulWidget {
  const _ConversationList();

  @override
  State<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<_ConversationList> {
  final _moreMenuController = FlyoutController();

  @override
  void deactivate() {
    context.chat.mayPause(context.rwkv);
    super.deactivate();
  }

  void _showMoreMenu() async {
    _moreMenuController.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.bottomCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (ctx) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              leading: const WindowsIcon(WindowsIcons.delete),
              text: const Text('清空对话'),
              onPressed: () => context.chat.clear(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Expanded(child: Text('对话')),
              IconButton(
                icon: const Icon(FluentIcons.add),
                onPressed: () => context.chat.newChat(),
              ),
              const SizedBox(width: 6),
              FlyoutTarget(
                controller: _moreMenuController,
                child: IconButton(
                  icon: const Icon(FluentIcons.more_vertical),
                  onPressed: _showMoreMenu,
                ),
              ),
            ],
          ),
        ),
        const Expanded(child: ChatList()),
      ],
    );
  }
}

class _Chat extends StatelessWidget {
  static const double maxWidth = 900;

  const _Chat();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.showSettingPanel != c.showSettingPanel,
      builder: (context, state) {
        return CollapsibleSidebarLayout(
          open: state.showSettingPanel,
          divider: const Divider(direction: .vertical),
          sidebar: const ChatSettingPanel(),
          content: LayoutBuilder(
            builder: (ctx, cs) {
              final float = cs.maxWidth > maxWidth;

              return ResizableSplitLayout(
                restoreId: 'spit-chat',
                autoHideDivider: float,
                fixed: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    constraints: const BoxConstraints(maxWidth: maxWidth),
                    margin: const .only(bottom: 6),
                    decoration: !float
                        ? const BoxDecoration()
                        : BoxDecoration(
                            borderRadius: .circular(8),
                            color: context.fluent.scaffoldBackgroundColor,
                            border: Border.all(
                              width: 1,
                              color: context.fluent.inactiveBackgroundColor,
                            ),
                          ),
                    child: const ChatMessageInput(),
                  ),
                ),
                flexible: const Column(
                  children: [
                    ChatTitleBar(),
                    Divider(),
                    Expanded(child: ChatMessageList(maxWidth: maxWidth)),
                  ],
                ),
                flexibleAlignEnd: false,
                direction: .vertical,
                size: 150,
                minSize: 100,
                maxSize: 300,
              );
            },
          ),
        );
      },
    );
  }
}
