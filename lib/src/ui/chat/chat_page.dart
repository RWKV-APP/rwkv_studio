import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/_chat_list.dart';
import 'package:rwkv_studio/src/ui/chat/_message_input.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list.dart';
import 'package:rwkv_studio/src/ui/chat/_title_bar.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_form.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';
import 'package:rwkv_studio/src/widget/side_bar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  void deactivate() {
    context.chat.mayPause(context.rwkv);
    super.deactivate();
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
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Text('对话')),
                    IconButton(
                      icon: const Icon(FluentIcons.add),
                      onPressed: () {
                        context.chat.newChat();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(child: ChatList()),
            ],
          ),
        ),
        Divider(direction: .vertical),
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
          divider: Divider(direction: .vertical),
          sidebar: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: _SettingPanel(),
          ),
          content: Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .max,
            children: [
              ChatTitleBar(),
              Divider(),
              Expanded(child: ChatMessageList()),
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
                  child: Padding(
                    padding: .symmetric(vertical: 4),
                    child: Divider(),
                  ),
                ),
              ),
              SizedBox(height: inputHeight, child: ChatMessageInput()),
            ],
          ),
        );
      },
    );
  }
}

class _SettingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      mainAxisSize: .max,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: Text('设置', style: TextStyle(fontSize: 18))),
            IconButton(
              icon: Icon(FluentIcons.chrome_close),
              onPressed: () {
                context.chat.toggleSettingPanelVisible();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Button(
          child: Text('重置'),
          onPressed: () {
            context.chat.resetSettings();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                BlocBuilder<ChatCubit, ChatState>(
                  buildWhen: (p, c) =>
                      p.decodeParam != c.decodeParam ||
                      p.generating != c.generating,
                  builder: (context, state) {
                    return DecodeParamForm(
                      param: state.decodeParam,
                      onChanged: state.generating
                          ? null
                          : (v) => context.chat.setDecodeParam(v),
                    );
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
