import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

const nodeHeaderHeight = 18.0;
const nodeSocketSize = 16.0;
const nodeSocketSpacing = 8.0;

final dataType2color = {
  NodeDataType.int: Colors.red.shade800,
  NodeDataType.float: Colors.blue.shade800,
  NodeDataType.string: Colors.green.shade800,
  NodeDataType.bool: Colors.yellow.shade800,
  NodeDataType.list: Colors.purple.shade800,
  NodeDataType.map: Colors.orange.shade800,
  NodeDataType.any: Colors.grey.shade800,
};

class NodeCardView extends StatefulWidget {
  final NodeCardState card;

  const NodeCardView({super.key, required this.card});

  @override
  State<NodeCardView> createState() => _NodeCardViewState();
}

class _NodeCardViewState extends State<NodeCardView> {
  Offset dragDownPos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<NodeInput?, NodeOutput?>>[];
    for (final input in widget.card.node.inputs) {
      rows.add(MapEntry(input, null));
    }
    for (final (index, output) in widget.card.node.outputs.indexed) {
      if (rows.length - 1 >= index) {
        rows[index] = MapEntry(rows[index].key, output);
      } else {
        rows.add(MapEntry(null, output));
      }
    }

    return DragEditable(
      handleRadius: 0,
      onStartUpdatePosition: (details) {
        dragDownPos = details.localPosition;
      },
      onUpdate: (details) {
        final pos = details.globalPosition - dragDownPos;
        context.editorCubit.updateNodePosition(widget.card, pos);
      },
      child: GestureDetector(
        onDoubleTap: () {
          context.editorCubit.removeNode(widget.card);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: nodeSocketSize / 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey.shade800,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: nodeHeaderHeight,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                      color: Colors.green,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.card.node.prototype.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: nodeHeaderHeight),
                for (final r in rows)
                  Container(
                    margin: EdgeInsets.only(top: nodeSocketSpacing),
                    height: nodeSocketSize,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (r.key != null)
                          Flexible(child: NodeSocketView(socket: r.key!)),
                        if (r.value != null)
                          Flexible(child: NodeSocketView(socket: r.value!)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NodeSocketView extends StatelessWidget {
  final NodeSocket socket;

  const NodeSocketView({super.key, required this.socket});

  @override
  Widget build(BuildContext context) {
    final output = socket is NodeOutput;

    final textStyle = TextStyle(
      color: Colors.grey.shade300,
      fontSize: 12,
      height: 1,
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
                  color: dataType2color[socket.prototype.type],
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
