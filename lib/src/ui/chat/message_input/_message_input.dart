import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/ui/common/decode_speed.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/app_split_button.dart';

part '_think_mode_button.dart';

part '_mcp_button.dart';

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
            IconButton(
              icon: const Icon(FluentIcons.add),
              onPressed: () {
                context.chat.newChat();
              },
            ),
            const SizedBox(width: 12),
            _ThinkModeButton(),
            const SizedBox(width: 6),
            _McpToggleButton(),
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
  Future<void> _onTapSend(BuildContext context) async {
    await context.chat.send(context.llm).withToast(context);
  }

  Future<void> _onTapPause(BuildContext context) async {
    await context.chat.pause(context.llm).withToast(context);
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
            onPressed: () async => _onTapPause(context),
          );
        }

        return Button(
          onPressed: !state.sendButtonEnabled
              ? null
              : () async => _onTapSend(context),
          child: const Row(
            children: [Text('发送'), SizedBox(width: 8), Icon(WindowsIcons.send)],
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
  @override
  void initState() {
    super.initState();
    _scheduleFocus();
  }

  @override
  void didUpdateWidget(covariant _LineBreakEventListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _scheduleFocus();
    }
  }

  void _scheduleFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.focusNode.hasFocus) {
        return;
      }
      widget.focusNode.requestFocus();
    });
  }

  bool get _isComposing {
    final composing = widget.controller.value.composing;
    return composing.isValid && !composing.isCollapsed;
  }

  Future<void> _sendMessage() async {
    await context.chat.send(context.llm).withToast(context);
    if (!mounted || widget.focusNode.hasFocus) {
      return;
    }
    widget.focusNode.requestFocus();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed ||
        _isComposing ||
        widget.controller.text.trim().isEmpty ||
        context.chat.state.generating) {
      return KeyEventResult.ignored;
    }

    unawaited(_sendMessage());
    return KeyEventResult.handled;
  }

  @override
  void deactivate() {
    widget.focusNode.unfocus();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      onKeyEvent: _handleKeyEvent,
      child: TextBox(
        focusNode: widget.focusNode,
        autofocus: false,
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
