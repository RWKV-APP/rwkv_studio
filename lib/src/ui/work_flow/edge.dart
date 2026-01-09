import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'node_editor_cubit.dart';

class EditingEdge extends StatelessWidget {
  const EditingEdge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NodeEditorCubit, NodeEditorState, EdgeEditingState>(
      selector: (state) => state.editingEdge,
      builder: (context, editing) {
        if (editing != EdgeEditingState.empty) {
          return CustomPaint(
            painter: NodeEdgeCustomPainter(
              end: editing.linkInput ? editing.toPos : editing.fromPos,
              start: editing.linkInput ? editing.fromPos : editing.toPos,
              startColor: editing.color,
              endColor: editing.color,
            ),
          );
        } else {
          return SizedBox();
        }
      },
    );
  }
}

class NodeEdgeCustomPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color startColor;

  final Color endColor;

  late final _paint = Paint()
    ..color = startColor
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  late final Offset center = (start + end) / 2;

  final offset = 35;

  NodeEdgeCustomPainter({
    required this.start,
    required this.end,
    required this.startColor,
    required this.endColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy - 2)
        ..quadraticBezierTo(start.dx + offset, start.dy, center.dx, center.dy)
        ..quadraticBezierTo(end.dx - offset, end.dy - 1, end.dx, end.dy - 1),
      _paint,
    );
  }

  @override
  bool shouldRepaint(NodeEdgeCustomPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.startColor != startColor ||
      oldDelegate.endColor != endColor;
}
