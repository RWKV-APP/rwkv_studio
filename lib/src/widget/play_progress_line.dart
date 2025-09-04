import 'package:flutter/material.dart';

class ProgressLine extends StatelessWidget {
  final double progress;

  const ProgressLine({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _Painter(progress: progress));
  }
}

class _Painter extends CustomPainter {
  final double progress;
  final _paint = Paint()
    ..color = Colors.redAccent
    ..strokeWidth = 1.5;

  _Painter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), _paint);
  }

  @override
  bool shouldRepaint(covariant _Painter oldDelegate) =>
      oldDelegate.progress != progress;
}
