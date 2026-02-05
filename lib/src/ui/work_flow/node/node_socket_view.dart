import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node/node_card_style.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

class NodeSocketView extends StatelessWidget {
  final NodeSocket socket;

  const NodeSocketView({super.key, required this.socket});

  @override
  Widget build(BuildContext context) {
    final output = socket is NodeOutput;
    final isControl = socket.prototype.type == NodeDataType.void_;

    final textStyle = TextStyle(
      color: isControl ? Colors.grey.shade400 : Colors.grey.shade300,
      fontSize: 12,
      height: 1,
      fontStyle: isControl ? FontStyle.italic : FontStyle.normal,
    );

    return Row(
      mainAxisAlignment: output
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (output)
          Flexible(
            child: Text(
              socket.prototype.name,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        if (output) const SizedBox(width: 6),
        SizedBox(
          width: nodeSocketSize,
          child: DragEditable(
            handleRadius: 0,
            onStartUpdatePosition: (details) {
              context.editorCubit.startLink(socket, details.globalPosition);
            },
            onUpdate: (details) {
              context.editorCubit.updateLink(details.globalPosition);
            },
            onUpdateEnd: (details) {
              context.editorCubit.endLink(details.globalPosition);
            },
            child: Center(
              child: Container(
                width: nodeSocketSize / 2,
                height: nodeSocketSize / 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(nodeSocketSize),
                  color:
                      dataType2color[socket.prototype.type] ??
                      Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
        if (!output) const SizedBox(width: 4),
        if (!output)
          Flexible(child: Text(socket.prototype.name, style: textStyle)),
      ],
    );
  }
}
