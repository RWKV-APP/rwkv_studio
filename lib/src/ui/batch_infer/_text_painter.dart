import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

bool _isHighSurrogateCodeUnit(int codeUnit) {
  return codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
}

bool _isLowSurrogateCodeUnit(int codeUnit) {
  return codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
}

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
    final int tailCharBudget = _estimateTailCharBudget(
      innerWidth: innerWidth,
      innerHeight: innerHeight,
      style: textStyle,
    );
    final bool useCache = cellCount <= _ParagraphCache.maxCacheFriendlyCells;

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

        final String text = _takeTailText(cells[idx], tailCharBudget);
        final ui.Paragraph paragraph = _ParagraphCache.instance.getOrBuild(
          styleKey,
          text,
          _pStyle,
          _uiStyle,
          cacheable: useCache,
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

  int _estimateTailCharBudget({
    required double innerWidth,
    required double innerHeight,
    required TextStyle style,
  }) {
    final double fontSize = style.fontSize ?? 14;
    final double lineHeight = fontSize * (style.height ?? 1.2);
    final double letterSpacing = style.letterSpacing ?? 0;

    // Character width approximation for mixed latin/cjk text.
    final double charWidth = (fontSize * 0.58 + letterSpacing)
        .clamp(1.0, 1024.0)
        .toDouble();
    final int lines = (innerHeight / lineHeight).floor().clamp(1, 1000);
    final int charsPerLine = (innerWidth / charWidth).floor().clamp(1, 10000);

    // Keep an extra line as buffer so bottom alignment remains stable.
    return ((lines + 1) * charsPerLine).clamp(32, 1200);
  }

  String _takeTailText(String text, int maxChars) {
    if (text.length <= maxChars) {
      return text;
    }
    int start = text.length - maxChars;
    if (start > 0) {
      final int codeUnit = text.codeUnitAt(start);
      if (_isLowSurrogateCodeUnit(codeUnit)) {
        start += 1;
      }
    }
    return text.substring(start);
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
      maxWidth: (maxWidth * 100).roundToDouble() / 100,
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

  static const int maxCacheFriendlyCells = 2048;
  static const int _maxEntries = 512;
  static final RegExp _asciiWordPattern = RegExp(r'[A-Za-z0-9_]{2,}');
  final LinkedHashMap<String, ui.Paragraph> _cache =
      LinkedHashMap<String, ui.Paragraph>();

  ui.Paragraph getOrBuild(
    _ParagraphStyleKey key,
    String text,
    ui.ParagraphStyle paragraphStyle,
    ui.TextStyle textStyle, {
    required bool cacheable,
  }) {
    final String breakableText = _insertWordBreakOpportunities(text);
    if (!cacheable) {
      final ui.ParagraphBuilder builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(breakableText);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(ui.ParagraphConstraints(width: key.maxWidth));
      return paragraph;
    }

    final String cacheKey = '${key.hashCode}\u0000$text';
    final ui.Paragraph? existed = _cache.remove(cacheKey);
    if (existed != null) {
      _cache[cacheKey] = existed;
      return existed;
    }
    ui.ParagraphBuilder builder;
    try {
      builder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(breakableText);
    } on ArgumentError {
      loge("=>$breakableText");
      builder = ui.ParagraphBuilder(paragraphStyle)..addText('');
    }
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: key.maxWidth));

    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = paragraph;

    return paragraph;
  }

  String _insertWordBreakOpportunities(String input) {
    final String safeInput = _toWellFormedUtf16(input);
    return safeInput.replaceAllMapped(_asciiWordPattern, (Match m) {
      final String word = m.group(0)!;
      if (word.length < 2) {
        return word;
      }
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < word.length; i++) {
        if (i > 0) {
          buffer.write('\u200B');
        }
        buffer.writeCharCode(word.codeUnitAt(i));
      }
      return buffer.toString();
    });
  }

  String _toWellFormedUtf16(String input) {
    bool changed = false;
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final int codeUnit = input.codeUnitAt(i);
      if (_isHighSurrogateCodeUnit(codeUnit)) {
        if (i + 1 < input.length) {
          final int nextCodeUnit = input.codeUnitAt(i + 1);
          if (_isLowSurrogateCodeUnit(nextCodeUnit)) {
            buffer.writeCharCode(codeUnit);
            buffer.writeCharCode(nextCodeUnit);
            i += 1;
            continue;
          }
        }
        changed = true;
        buffer.write('\uFFFD');
        continue;
      }
      if (_isLowSurrogateCodeUnit(codeUnit)) {
        changed = true;
        buffer.write('\uFFFD');
        continue;
      }
      buffer.writeCharCode(codeUnit);
    }
    return changed ? buffer.toString() : input;
  }
}
