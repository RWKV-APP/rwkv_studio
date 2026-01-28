import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/common/decode_speed.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';

class ChatMessageInput extends StatelessWidget {
  const ChatMessageInput({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (p, c) => p.inputController != c.inputController,
            builder: (context, state) {
              return _LineBreakEventListener(
                focusNode: state.inputFocusNode,
                controller: state.inputController,
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
                return DecodeSpeedInfo(modelInstanceId: state.modelInstanceId);
              },
            ),
            const SizedBox(width: 12),
            _SendButton(),
            const SizedBox(width: 16),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  void _onTapSend(BuildContext context) {
    context.chat.send(context.rwkv).withToast(context);
  }

  void _onTapPause(BuildContext context) {
    context.chat.pause(context.rwkv).withToast(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.sendButtonEnabled != c.sendButtonEnabled,
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

        return Button(
          onPressed: !state.sendButtonEnabled
              ? null
              : () => _onTapSend(context),
          child: Row(
            children: [
              Text('发送'),
              const SizedBox(width: 8),
              Icon(WindowsIcons.send),
            ],
          ),
        );
      },
    );
  }
}

class _ThinkModeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatCubit, ChatState>(
      buildWhen: (p, c) => p.generationConfig != c.generationConfig,
      builder: (context, state) {
        return SplitButton.toggle(
          checked: state.generationConfig.chatReasoning,
          onInvoked: () {
            context.chat.toggleThinkMode();
          },
          flyout: FlyoutContent(
            constraints: BoxConstraints(maxWidth: 200.0),
            child: Wrap(
              runSpacing: 10.0,
              spacing: 8.0,
              children: Colors.accentColors.map((color) {
                return Button(
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(
                      EdgeInsetsDirectional.all(4.0),
                    ),
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
      },
    );
  }
}

class _LineBreakEventListener extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;

  const _LineBreakEventListener({
    required this.focusNode,
    required this.controller,
  });

  @override
  State<_LineBreakEventListener> createState() =>
      _LineBreakEventListenerState();
}

class _LineBreakEventListenerState extends State<_LineBreakEventListener> {
  final focusNode = FocusNode();
  bool shiftDown = false;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      onKeyEvent: (e) {
        if (e.physicalKey == PhysicalKeyboardKey.shiftLeft) {
          shiftDown = e is KeyDownEvent;
        }
        if (e.physicalKey == PhysicalKeyboardKey.enter && e is KeyDownEvent) {
          if (!shiftDown) {
            context.chat.send(context.rwkv).withToast(context);
          }
        }
      },
      child: TextBox(
        focusNode: widget.focusNode,
        autofocus: true,
        controller: widget.controller,
        foregroundDecoration: WidgetStatePropertyAll(
          BoxDecoration(border: Border(), color: Colors.transparent),
        ),
        decoration: WidgetStatePropertyAll(
          BoxDecoration(border: Border(), color: Colors.transparent),
        ),
        placeholder: '请输入内容',
        maxLines: 1000000,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
