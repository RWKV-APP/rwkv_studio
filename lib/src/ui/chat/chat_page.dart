import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/_chat_list.dart';
import 'package:rwkv_studio/src/ui/chat/_message_input.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list.dart';
import 'package:rwkv_studio/src/ui/chat/_title_bar.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';
import 'package:rwkv_studio/src/widget/side_bar.dart';

import '_chat_setting_pannel.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _moreMenuController = FlyoutController();

  @override
  void initState() {
    super.initState();
  }

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
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
          ),
        ),
        const Divider(direction: .vertical),
        Expanded(flex: 3, child: _Chat()),
      ],
    );
  }
}

class _Chat extends StatefulWidget {
  @override
  State<_Chat> createState() => _ChatState();
}

class _ChatState extends State<_Chat> {
  Offset down = Offset.zero;

  static double inputHeight = 150;
  double downHeight = 150;
  double maxHeight = 400;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.showSettingPanel != c.showSettingPanel,
      builder: (context, state) {
        return CollapsibleSidebarLayout(
          open: state.showSettingPanel,
          divider: const Divider(direction: .vertical),
          sidebar: const ChatSettingPanel(),
          content: Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .max,
            children: [
              const ChatTitleBar(),
              const Divider(),
              const Expanded(child: ChatMessageList()),
              MouseRegion(
                cursor: SystemMouseCursors.resizeUpDown,
                child: DragEditable(
                  handleRadius: 0,
                  onStartUpdatePosition: (detail) {
                    down = detail.globalPosition;
                    downHeight = inputHeight;
                    final renderBox = context.findRenderObject() as RenderBox;
                    maxHeight = renderBox.size.height - 150;
                  },
                  onUpdate: (detail) {
                    final pos = detail.globalPosition - down;
                    inputHeight = (downHeight - pos.dy).clamp(100, maxHeight);
                    setState(() {});
                  },
                  onUpdateEnd: (d) {
                    //
                  },
                  child: const Padding(
                    padding: .symmetric(vertical: 4),
                    child: Divider(),
                  ),
                ),
              ),
              SizedBox(height: inputHeight, child: const ChatMessageInput()),
            ],
          ),
        );
      },
    );
  }
}
