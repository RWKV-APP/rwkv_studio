import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/chat/_chat_list.dart';
import 'package:rwkv_studio/src/ui/chat/_message_input.dart';
import 'package:rwkv_studio/src/ui/chat/_message_list.dart';
import 'package:rwkv_studio/src/ui/chat/_title_bar.dart';
import 'package:rwkv_studio/src/ui/common/decode_param_form.dart';
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

class _Chat extends StatelessWidget {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChatTitleBar(),
              Divider(),
              Expanded(child: ChatMessageList()),
              Divider(),
              ChatMessageInput(),
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
