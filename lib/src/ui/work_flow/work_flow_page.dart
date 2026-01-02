import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class WorkFlowPage extends StatelessWidget {
  const WorkFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.grey, child: _Editor());
  }
}

class _Editor extends StatelessWidget {
  final FocusNode focusNode = FocusNode();

  void _onKeyEvent(KeyEvent event) {
    logd('key event: $event');
  }

  void _onPointerUp(PointerEvent event) {
    logd('pointer up: ${event.kind}, ${event.buttons}');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: NodeEditor(),
    );
  }
}
