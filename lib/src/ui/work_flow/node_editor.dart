import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/ui/work_flow/edge.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';

import 'node_card.dart';

class NodeEditor extends StatelessWidget {
  final focusNode = FocusNode();

  NodeEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (e) {
        //
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onSecondaryTapUp: (detail) {
          final rb = context.findRenderObject() as RenderBox?;
          final local = rb!.globalToLocal(detail.globalPosition);
          final pos = local - Offset(10, 0);
          showMenu(
            position: RelativeRect.fromLTRB(
              pos.dx,
              pos.dy,
              pos.dx + 100,
              pos.dy + 100,
            ),
            context: context,
            items: [
              PopupMenuItem(
                child: Text('Add'),
                onTap: () {
                  context.editorCubit.addNode(pos, addNodeProto);
                },
              ),
              PopupMenuItem(
                child: Text('Multiply'),
                onTap: () {
                  context.editorCubit.addNode(pos, multiplyNodeProto);
                },
              ),
            ],
          );
        },
        child: Container(
          color: Colors.grey.shade900,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BlocBuilder<NodeEditorCubit, NodeEditorState>(
                buildWhen: (p, c) => p.edges != c.edges || p.cards != c.cards,
                builder: (context, state) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      /// Edges
                      for (final edge in state.edges.values)
                        CustomPaint(
                          painter: NodeEdgeCustomPainter(
                            start: state.cards[edge.from]!.getOutputPosition(
                              edge.fromSocket,
                            ),
                            end: state.cards[edge.targetNode]!.getInputPosition(
                              edge.targetSocket,
                            ),
                            color: edge.color,
                          ),
                        ),
                    ],
                  );
                },
              ),

              /// Editing Edge
              EditingEdge(),

              BlocBuilder<NodeEditorCubit, NodeEditorState>(
                buildWhen: (p, c) => p.cards != c.cards,
                builder: (context, state) {
                  return Stack(
                    key: state.keyCanvas,
                    children: [
                      /// Nodes
                      for (final card in state.cards.values)
                        Positioned(
                          left: card.bounds.left,
                          top: card.bounds.top,
                          width: card.bounds.width,
                          height: card.bounds.height,
                          child: NodeCardView(card: card),
                        ),

                      Positioned(
                        right: 20,
                        top: 20,
                        child: Column(
                          children: [
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                context.editorCubit.clear();
                              },
                              icon: Icon(Icons.cleaning_services_sharp),
                            ),
                            const SizedBox(height: 8),
                            IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                context.editorCubit.link();
                              },
                              icon: Icon(Icons.link),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
