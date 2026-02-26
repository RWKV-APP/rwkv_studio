import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class GridBackgroundPainter extends CustomPainter {
  GridBackgroundPainter({
    required this.rows,
    required this.cols,
    this.gridColor = const Color(0xFFD7DCE5),
    this.strokeWidth = 0.5,
    super.repaint,
  });

  final int rows;
  final int cols;
  final Color gridColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) {
      return;
    }

    canvas.clipRect(Offset.zero & size);

    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;
    if (cellWidth <= 0 ||
        cellHeight <= 0 ||
        cellWidth.isNaN ||
        cellHeight.isNaN ||
        cellWidth.isInfinite ||
        cellHeight.isInfinite) {
      return;
    }

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final Path gridPath = Path();

    for (int c = 0; c <= cols; c++) {
      final double x = c * cellWidth;
      gridPath.moveTo(x, 0);
      gridPath.lineTo(x, size.height);
    }

    for (int r = 0; r <= rows; r++) {
      final double y = r * cellHeight;
      gridPath.moveTo(0, y);
      gridPath.lineTo(size.width, y);
    }

    canvas.drawPath(gridPath, gridPaint);
  }

  @override
  bool shouldRepaint(covariant GridBackgroundPainter old) {
    return old.rows != rows ||
        old.cols != cols ||
        old.gridColor != gridColor ||
        old.strokeWidth != strokeWidth;
  }
}

class GridTailParagraphPainter extends CustomPainter {
  GridTailParagraphPainter({
    required this.cells,
    required this.rows,
    required this.cols,
    required this.textStyle,
    this.colSpacing = 0,
    this.rowSpacing = 0,
    super.repaint,
  });

  final List<String> cells;
  final int rows;
  final int cols;
  final TextStyle textStyle;
  final double colSpacing;
  final double rowSpacing;

  late final ui.ParagraphStyle _pStyle = ui.ParagraphStyle(
    fontFamily: textStyle.fontFamily,
    fontSize: textStyle.fontSize,
  );

  ui.TextStyle get _uiStyle => ui.TextStyle(
    color: textStyle.color,
    fontSize: textStyle.fontSize,
    fontFamily: textStyle.fontFamily,
    height: textStyle.height,
    fontWeight: textStyle.fontWeight,
    letterSpacing: textStyle.letterSpacing,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (rows <= 0 || cols <= 0) {
      return;
    }

    canvas.clipRect(Offset.zero & size);

    final int maxCells = rows * cols;
    final int cellCount = cells.length < maxCells ? cells.length : maxCells;
    final double safeHorizontalSpacing = colSpacing < 0 ? 0 : colSpacing;
    final double safeVerticalSpacing = rowSpacing < 0 ? 0 : rowSpacing;
    final double cellWidth = size.width / cols;
    final double cellHeight = size.height / rows;
    final double innerWidth = cellWidth - safeHorizontalSpacing * 2;
    final double innerHeight = cellHeight - safeVerticalSpacing * 2;
    if (cellWidth <= 0 ||
        cellHeight <= 0 ||
        cellWidth.isNaN ||
        cellHeight.isNaN ||
        cellWidth.isInfinite ||
        cellHeight.isInfinite ||
        innerWidth <= 0 ||
        innerHeight <= 0) {
      return;
    }

    final _ParagraphStyleKey styleKey = _ParagraphStyleKey.fromTextStyle(
      textStyle,
      innerWidth,
    );

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final int idx = r * cols + c;
        final double cellLeft = c * cellWidth;
        final double cellTop = r * cellHeight;
        final double left = cellLeft + safeHorizontalSpacing;
        final double top = cellTop + safeVerticalSpacing;
        final Rect rect = Rect.fromLTWH(left, top, innerWidth, innerHeight);
        if (idx >= cellCount) {
          continue;
        }

        final String text = cells[idx];
        final ui.Paragraph paragraph = _ParagraphCache.instance.getOrBuild(
          styleKey,
          text,
          _pStyle,
          _uiStyle,
        );
        final double dy = top + innerHeight - paragraph.height;

        if (paragraph.height > innerHeight) {
          canvas.save();
          canvas.clipRect(rect);
          canvas.drawParagraph(paragraph, Offset(left, dy));
          canvas.restore();
        } else {
          canvas.drawParagraph(paragraph, Offset(left, dy));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridTailParagraphPainter old) {
    return !identical(old.cells, cells) ||
        old.colSpacing != colSpacing ||
        old.rowSpacing != rowSpacing ||
        old.textStyle != textStyle ||
        old.rows != rows ||
        old.cols != cols;
  }
}

class _ParagraphStyleKey {
  _ParagraphStyleKey({
    required this.fontFamily,
    required this.fontSize,
    required this.height,
    required this.fontWeight,
    required this.letterSpacing,
    required this.color,
    required this.maxWidth,
  });

  factory _ParagraphStyleKey.fromTextStyle(TextStyle style, double maxWidth) {
    return _ParagraphStyleKey(
      fontFamily: style.fontFamily ?? '',
      fontSize: style.fontSize ?? 14,
      height: style.height,
      fontWeight: style.fontWeight,
      letterSpacing: style.letterSpacing,
      color: style.color,
      maxWidth: maxWidth,
    );
  }

  final String fontFamily;
  final double fontSize;
  final double? height;
  final FontWeight? fontWeight;
  final double? letterSpacing;
  final Color? color;
  final double maxWidth;

  @override
  int get hashCode => Object.hash(
    fontFamily,
    fontSize,
    height,
    fontWeight,
    letterSpacing,
    color,
    maxWidth,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _ParagraphStyleKey &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.height == height &&
        other.fontWeight == fontWeight &&
        other.letterSpacing == letterSpacing &&
        other.color == color &&
        other.maxWidth == maxWidth;
  }
}

class _ParagraphCache {
  _ParagraphCache._();

  static final _ParagraphCache instance = _ParagraphCache._();

  static const int _maxEntries = 512;
  static final RegExp _asciiWordPattern = RegExp(r'[A-Za-z0-9_]{2,}');
  final LinkedHashMap<String, ui.Paragraph> _cache =
      LinkedHashMap<String, ui.Paragraph>();

  ui.Paragraph getOrBuild(
    _ParagraphStyleKey key,
    String text,
    ui.ParagraphStyle paragraphStyle,
    ui.TextStyle textStyle,
  ) {
    final String cacheKey = '${key.hashCode}\u0000$text';
    final ui.Paragraph? existed = _cache.remove(cacheKey);
    if (existed != null) {
      _cache[cacheKey] = existed;
      return existed;
    }

    final String breakableText = _insertWordBreakOpportunities(text);
    final ui.ParagraphBuilder builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle)
      ..addText(breakableText);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: key.maxWidth));

    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = paragraph;

    return paragraph;
  }

  String _insertWordBreakOpportunities(String input) {
    return input.replaceAllMapped(_asciiWordPattern, (Match m) {
      final String word = m.group(0)!;
      if (word.length < 2) {
        return word;
      }
      return word.split('').join('\u200B');
    });
  }
}
