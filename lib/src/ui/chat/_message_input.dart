import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/global/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/global/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/common/decode_speed.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ChatMessageInput extends StatelessWidget {
  const ChatMessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .max,
        children: [
          Expanded(
            child: BlocBuilder<ChatCubit, ChatState>(
              buildWhen: (p, c) => p.inputController != c.inputController,
              builder: (context, state) {
                return TextBox(
                  autofocus: true,
                  controller: state.inputController,
                  foregroundDecoration: WidgetStatePropertyAll(
                    BoxDecoration(border: Border(), color: Colors.transparent),
                  ),
                  decoration: WidgetStatePropertyAll(
                    BoxDecoration(border: Border(), color: Colors.transparent),
                  ),
                  placeholder: '请输入内容',
                  onSubmitted: (String text) => context.chat.send(context.rwkv),
                  maxLines: 1,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                );
              },
            ),
          ),
          Row(
            mainAxisSize: .max,
            children: [
              const SizedBox(width: 12),
              _ThinkModeButton(),
              Spacer(),
              BlocBuilder<ChatCubit, ChatState>(
                buildWhen: (p, c) => p.modelInstanceId != c.modelInstanceId,
                builder: (context, state) {
                  return DecodeSpeedInfo(
                    modelInstanceId: state.modelInstanceId,
                  );
                },
              ),
              const SizedBox(width: 12),
              _SendButton(),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  void _onTapSend(BuildContext context) {
    context.chat.send(context.rwkv);
  }

  void _onTapPause(BuildContext context) {
    context.chat.pause(context.rwkv).withToast(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        if (state.generating) {
          return Button(
            child: Row(
              children: [
                SizedBox(width: 14, height: 14, child: ProgressRing()),
                const SizedBox(width: 4),
                Text('暂停'),
              ],
            ),
            onPressed: () => _onTapPause(context),
          );
        }

        return Button(child: Text('发送'), onPressed: () => _onTapSend(context));
      },
    );
  }
}

class _ThinkModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SplitButton.toggle(
      checked: false,
      onInvoked: () {
        context.chat.newChat();
      },
      flyout: FlyoutContent(
        constraints: BoxConstraints(maxWidth: 200.0),
        child: Wrap(
          runSpacing: 10.0,
          spacing: 8.0,
          children: Colors.accentColors.map((color) {
            return Button(
              style: ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsetsDirectional.all(4.0)),
              ),
              onPressed: () {
                Navigator.of(context).pop(color);
              },
              child: Container(height: 32, width: 32, color: color),
            );
          }).toList(),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 8, vertical: 4),
        child: Text('思考'),
      ),
    );
  }
}
