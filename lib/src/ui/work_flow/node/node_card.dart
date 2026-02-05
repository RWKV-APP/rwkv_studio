import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node/node_card_content.dart';
import 'package:rwkv_studio/src/ui/work_flow/node/node_card_style.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

class NodeCardView extends StatefulWidget {
  final NodeCardState card;
  final Set<SocketId> connectedInputs;

  const NodeCardView({
    super.key,
    required this.card,
    required this.connectedInputs,
  });

  @override
  State<NodeCardView> createState() => _NodeCardViewState();
}

class _NodeCardViewState extends State<NodeCardView> {
  Offset dragDownPos = Offset.zero;
  bool highlight = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (p) {
        setState(() {
          highlight = true;
        });
      },
      onExit: (p) {
        setState(() {
          highlight = false;
        });
      },
      child: DragEditable(
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
          child: buildContent(context),
        ),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
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

    final node = widget.card.node;

    return NodeCardContent(
      title: node.prototype.name,
      rows: rows,
      autoControlIn: autoControlIn,
      showAutoControl: highlight,
      onStartLink: (socket, position) {
        context.editorCubit.startLink(socket, position);
      },
      onUpdateLink: (position) {
        context.editorCubit.updateLink(position);
      },
      onEndLink: (position) {
        context.editorCubit.endLink(position);
      },
      bodyDecoration: nodeCardBodyDecoration,
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
