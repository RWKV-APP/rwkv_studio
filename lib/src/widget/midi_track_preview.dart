import 'package:flutter/material.dart';

class MidiNote {
  final int note;
  final double start;
  final double duration;

  MidiNote({required this.note, required this.start, required this.duration});
}

class MidiTrackPreview extends StatefulWidget {
  final List<MidiNote> notes;
  final double trackDuration;

  const MidiTrackPreview({
    super.key,
    required this.notes,
    required this.trackDuration,
  });

  @override
  State<MidiTrackPreview> createState() => _MidiTrackPreviewState();
}

class _MidiTrackPreviewState extends State<MidiTrackPreview> {
  List<MidiNote> notes = [];

  @override
  void initState() {
    super.initState();
    notes.addAll(widget.notes);
    notes.sort((a, b) => a.note.compareTo(b.note));
  }

  @override
  void didUpdateWidget(covariant MidiTrackPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes) {
      notes.clear();
      notes.addAll(widget.notes);
      notes.sort((a, b) => a.note.compareTo(b.note));
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackPreviewPainter(
        notes: widget.notes,
        trackDuration: widget.trackDuration,
      ),
    );
  }
}

class _TrackPreviewPainter extends CustomPainter {
  final List<MidiNote> notes;
  final double trackDuration;
  final Paint _paint = Paint()
    ..color = Colors.teal
    ..isAntiAlias = true;

  _TrackPreviewPainter({required this.notes, required this.trackDuration});

  @override
  void paint(Canvas canvas, Size size) {
    if (notes.isEmpty) return;
    final max = notes.last.note;
    final min = notes.first.note - 1;
    final rowHeight = size.height / (max - min);
    final widthPerSecond = size.width / trackDuration;
    for (final note in notes) {
      final left = note.start * widthPerSecond;
      final width = note.duration * widthPerSecond;
      final dst = rowHeight * ((note.note - min));
      Rect rect = Rect.fromLTWH(left, size.height - dst, width, rowHeight);
      canvas.drawRect(rect, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPreviewPainter oldDelegate) =>
      oldDelegate.notes != notes;
}
