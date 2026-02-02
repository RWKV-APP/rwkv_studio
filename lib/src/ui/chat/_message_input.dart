import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/ui/common/decode_speed.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/app_split_button.dart';

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
            const Spacer(),
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
            child: const Row(
              children: [
                SizedBox(width: 14, height: 14, child: ProgressRing()),
                SizedBox(width: 4),
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
          child: const Row(
            children: [Text('发送'), SizedBox(width: 8), Icon(WindowsIcons.send)],
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
        String label = '';
        bool checked = true;
        switch (state.generationConfig.reasoningEffort) {
          case ReasoningEffort.none:
            label = '推理-关';
            checked = false;
            break;
          case ReasoningEffort.mini:
          case ReasoningEffort.low:
            label = '推理-低';
            break;
          case ReasoningEffort.medium:
            label = '推理-中';
            break;
          case ReasoningEffort.high:
          case ReasoningEffort.xhig:
            label = '推理-高';
            break;
        }

        return AppSplitButton.toggle(
          checked: checked,
          onInvoked: () {
            context.chat.toggleReasoningEnable();
          },
          flyout: MenuFlyout(
            items: [
              MenuFlyoutItem(
                text: const Text('推理-中'),
                onPressed: () {
                  context.chat.setReasoningMode(ReasoningEffort.medium);
                },
              ),
              MenuFlyoutItem(
                text: const Text('推理-高'),
                onPressed: () {
                  context.chat.setReasoningMode(ReasoningEffort.high);
                },
              ),
            ],
          ),
          child: Padding(
            padding: const .symmetric(horizontal: 8, vertical: 4),
            child: Text(label),
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
        foregroundDecoration: const WidgetStatePropertyAll(
          BoxDecoration(border: Border(), color: Colors.transparent),
        ),
        decoration: const WidgetStatePropertyAll(
          BoxDecoration(border: Border(), color: Colors.transparent),
        ),
        placeholder: '请输入内容',
        maxLines: 1000000,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
