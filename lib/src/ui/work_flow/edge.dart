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
              end: editing.output2input ? editing.toPos : editing.fromPos,
              start: editing.output2input ? editing.fromPos : editing.toPos,
              color: editing.color,
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
  final Color color;

  late final _paint = Paint()
    ..color = color
    ..strokeWidth = 2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  late final Offset center = (start + end) / 2;

  final offset = 35;

  NodeEdgeCustomPainter({
    required this.start,
    required this.end,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(start.dx + offset, start.dy, center.dx, center.dy)
        ..quadraticBezierTo(end.dx - offset, end.dy, end.dx, end.dy),
      _paint,
    );
  }

  @override
  bool shouldRepaint(NodeEdgeCustomPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.color != color;
}
