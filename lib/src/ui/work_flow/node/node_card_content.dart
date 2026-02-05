import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/node/export.dart';
import 'package:rwkv_studio/src/ui/work_flow/node/node_card_style.dart';
import 'package:rwkv_studio/src/ui/work_flow/node/node_socket_view.dart';
import 'package:rwkv_studio/src/widget/drag_edit_recognizer.dart';

class NodeCardContent extends StatelessWidget {
  final String title;
  final List<MapEntry<NodeSocket?, NodeSocket?>> rows;
  final NodeSocket? autoControlIn;
  final bool showAutoControl;
  final void Function(NodeSocket socket, Offset globalPosition) onStartLink;
  final void Function(Offset globalPosition) onUpdateLink;
  final void Function(Offset globalPosition) onEndLink;
  final Decoration bodyDecoration;
  final EdgeInsetsGeometry headerPadding;
  final Decoration headerDecoration;
  final TextStyle headerTextStyle;

  const NodeCardContent({
    super.key,
    required this.title,
    required this.rows,
    required this.autoControlIn,
    required this.showAutoControl,
    required this.onStartLink,
    required this.onUpdateLink,
    required this.onEndLink,
    required this.bodyDecoration,
    this.headerPadding = nodeCardHeaderPadding,
    this.headerDecoration = nodeCardHeaderDecoration,
    this.headerTextStyle = nodeCardHeaderTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: nodeSocketSize / 2),
          decoration: bodyDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: nodeHeaderHeight,
                padding: headerPadding,
                decoration: headerDecoration,
                alignment: Alignment.centerLeft,
                child: Text(title, style: headerTextStyle),
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
        if (showAutoControl || autoControlIn != null)
          Positioned(
            left: 0,
            width: nodeSocketSize,
            top: nodeHeaderHeight / 2 - nodeSocketSize / 2,
            height: nodeSocketSize,
            child: _AutoControlPort(
              socket: autoControlIn,
              onStartLink: onStartLink,
              onUpdateLink: onUpdateLink,
              onEndLink: onEndLink,
            ),
          ),
      ],
    );
  }
}

class _AutoControlPort extends StatelessWidget {
  final NodeSocket? socket;
  final void Function(NodeSocket socket, Offset globalPosition) onStartLink;
  final void Function(Offset globalPosition) onUpdateLink;
  final void Function(Offset globalPosition) onEndLink;

  const _AutoControlPort({
    required this.socket,
    required this.onStartLink,
    required this.onUpdateLink,
    required this.onEndLink,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Container(
        width: nodeSocketSize / 4,
        height: nodeSocketSize * (2 / 3),
        decoration: BoxDecoration(color: Colors.orangeAccent.shade700),
      ),
    );
    if (socket == null) {
      return content;
    }
    return DragEditable(
      handleRadius: 0,
      onStartUpdatePosition: (details) {
        onStartLink(socket!, details.globalPosition);
      },
      onUpdate: (details) {
        onUpdateLink(details.globalPosition);
      },
      onUpdateEnd: (details) {
        onEndLink(details.globalPosition);
      },
      child: content,
    );
  }
}
