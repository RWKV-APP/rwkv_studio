import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

const nodeHeaderHeight = 18.0;
const nodeSocketSize = 16.0;
const nodeSocketSpacing = 8.0;

final dataType2color = {
  NodeDataType.int: Colors.red.shade800,
  NodeDataType.double: Colors.blueGrey.shade700,
  NodeDataType.float: Colors.blue.shade800,
  NodeDataType.string: Colors.green.shade800,
  NodeDataType.bool: Colors.yellow.shade800,
  NodeDataType.list: Colors.purple.shade800,
  NodeDataType.map: Colors.orange.shade800,
  NodeDataType.any: Colors.white,
  NodeDataType.void_: Colors.grey.shade600,
};

class NodeCardView extends StatefulWidget {
  final NodeCardState card;
  final Set<SocketId> connectedInputs;
  final Set<SocketId> connectedOutputs;

  const NodeCardView({
    super.key,
    required this.card,
    required this.connectedInputs,
    required this.connectedOutputs,
  });

  @override
  State<NodeCardView> createState() => _NodeCardViewState();
}

class _NodeCardViewState extends State<NodeCardView> {
  Offset dragDownPos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<NodeSocket?, NodeSocket?>>[];
    final autoControlIn = _autoControlIn();
    final inputs = widget.card.node.allInputs
        .where((socket) => socket != autoControlIn)
        .where(_shouldShowSocket)
        .toList(growable: false);
    final outputs = widget.card.node.allOutputs
        .where(_shouldShowSocket)
        .toList(growable: false);
    for (final input in inputs) {
      rows.add(MapEntry(input, null));
    }
    for (final (index, output) in outputs.indexed) {
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
              margin: const EdgeInsets.symmetric(horizontal: nodeSocketSize / 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey.shade800,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: nodeHeaderHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                      color: Colors.green,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.card.node.prototype.name,
                      style: const TextStyle(
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
                    margin: const EdgeInsets.only(top: nodeSocketSpacing),
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
            if (autoControlIn != null)
              Positioned(
                left: 0,
                width: nodeSocketSize,
                top: nodeHeaderHeight / 2 - nodeSocketSize / 2,
                height: nodeSocketSize,
                child: _AutoControlPort(socket: autoControlIn),
              ),
          ],
        ),
      ),
    );
  }

  NodeControlIn? _autoControlIn() {
    final node = widget.card.node;
    if (node.prototype.controlInputs.isNotEmpty || node.inputs.isEmpty) {
      return null;
    }
    if (node.controlInputs.isEmpty) {
      return null;
    }
    final control = node.controlInputs.first;
    if (!widget.connectedInputs.contains(control.id)) {
      return null;
    }
    return control;
  }

  bool _shouldShowSocket(NodeSocket socket) {
    final node = widget.card.node;
    final isAutoControlIn =
        socket is NodeControlIn &&
        node.prototype.controlInputs.isEmpty &&
        node.inputs.isNotEmpty;
    if (!isAutoControlIn) {
      return true;
    }
    return widget.connectedInputs.contains(socket.id);
  }
}

class _AutoControlPort extends StatelessWidget {
  final NodeSocket socket;

  const _AutoControlPort({required this.socket});

  @override
  Widget build(BuildContext context) {
    return DragEditable(
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
            color: Colors.orangeAccent.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
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
