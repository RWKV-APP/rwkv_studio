import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/midi/midi_view_state.dart';

class TrackEditorView extends StatelessWidget {
  final double keyHeight = 14;
  final double widthPerSecond = 60;
  final List<MidiNoteViewState> notes;

  const TrackEditorView({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widthPerSecond * 60 * 3,
          height: 11 * (12) * keyHeight,
          child: Stack(
            children: [
              // background
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.grey.shade600,
                  child: CustomPaint(
                    painter: GridLineCustomPainter(stepX: 15, stepY: keyHeight),
                  ),
                ),
              ),
              for (final note in notes) buildNoteEvent(note),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNoteEvent(MidiNoteViewState note) {
    return Positioned(
      width: note.durationSeconds * widthPerSecond,
      height: keyHeight,
      top: (keyHeight * 127) - (note.note) * keyHeight,
      left: note.startSeconds * widthPerSecond,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: Colors.cyan,
        ),
        child: Text(note.name, style: TextStyle(fontSize: 12, height: 1)),
      ),
    );
  }
}

class GridLineCustomPainter extends CustomPainter {
  final double stepX;
  final double stepY;

  GridLineCustomPainter({
    super.repaint,
    required this.stepX,
    required this.stepY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = 0.05;
    final x = 0.1;
    final l = 0.14;
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = x
      ..style = PaintingStyle.stroke;

    for (var y = 0.0; y < size.height; y += stepY) {
      if ((y / stepY) % 5 == 0) {
        paint.strokeWidth = l;
      } else {
        paint.strokeWidth = s;
      }
      final path = Path();
      path.moveTo(0, y);
      path.lineTo(size.width, y);
      canvas.drawPath(path, paint);
    }
    for (var x = 0.0; x < size.width; x += stepX) {
      if ((x / stepX) % 16 == 0) {
        paint.strokeWidth = l;
      } else if ((x / stepX) % 8 == 0) {
        paint.strokeWidth = 0.08;
      } else {
        paint.strokeWidth = s;
      }
      final path = Path();
      path.moveTo(x, 0);
      path.lineTo(x, size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
