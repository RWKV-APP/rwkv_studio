import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/ui/work_flow/edge.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_editor_cubit.dart';
import 'package:rwkv_studio/src/ui/work_flow/node_prototypes.dart';

import 'node_card.dart';

class NodeEditor extends StatelessWidget {
  final focusNode = FocusNode();
  final TransformationController controller = TransformationController();

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
              for (final proto in NodePrototypes.list)
                PopupMenuItem(
                  child: Text(proto.name),
                  onTap: () {
                    context.editorCubit.addNode(pos, proto);
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
              InteractiveViewer(
                maxScale: 10,
                minScale: 0.2,
                constrained: false,
                transformationController: controller,
                child: SizedBox(
                  height: 10000,
                  width: 10000,
                  child: _buildNodeEditor(),
                ),
              ),

              Positioned(
                right: 20,
                top: 20,
                child: IconButtonTheme(
                  data: IconButtonThemeData(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.grey.shade200,
                      ),
                    ),
                  ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeEditor() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _EditorBackground()),

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
                      startColor: edge.color,
                      endColor: edge.color,
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
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EditorBackground extends CustomPainter {
  late final _paint = Paint()
    ..color = Color(0xFF2F2F2F)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    //draw grid
    final step = 50;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), _paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), _paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
