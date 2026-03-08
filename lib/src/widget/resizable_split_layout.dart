import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';

import 'drag_edit_recognizer.dart';

class ResizableSplitLayout extends StatefulWidget {
  final Widget fixed;
  final Widget flexible;
  final Axis direction;
  final double size;
  final double minSize;
  final double maxSize;
  final bool flexibleAlignEnd;
  final String? restoreId;
  final bool hideFixedWidget;

  const ResizableSplitLayout({
    super.key,
    required this.fixed,
    required this.flexible,
    required this.direction,
    required this.size,
    required this.minSize,
    required this.maxSize,
    this.restoreId,
    this.flexibleAlignEnd = true,
    this.hideFixedWidget = false,
  }) : assert(
         minSize <= maxSize,
         'minSize must be less than or equal to maxSize.',
       );

  @override
  State<ResizableSplitLayout> createState() => _ResizableSplitLayoutState();
}

class _ResizableSplitLayoutState extends State<ResizableSplitLayout> {
  Offset _dragStartPosition = Offset.zero;
  late double _size;
  double _dragStartSize = 0;
  bool _isDividerHighlighted = false;
  bool _didRestoreSize = false;

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  bool get _isFixedLeading => widget.flexibleAlignEnd;

  @override
  void initState() {
    super.initState();
    _size = _clampSize(widget.size);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _restoreSizeFromStorage();
  }

  @override
  void didUpdateWidget(covariant ResizableSplitLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.restoreId != widget.restoreId) {
      _didRestoreSize = false;
      if (widget.restoreId == null) {
        _size = _clampSize(widget.size);
      } else {
        _restoreSizeFromStorage();
      }
    }

    if (widget.restoreId == null && oldWidget.size != widget.size) {
      _size = _clampSize(widget.size);
    }

    if (oldWidget.minSize != widget.minSize ||
        oldWidget.maxSize != widget.maxSize) {
      _size = _clampSize(_size);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideFixedWidget) {
      return widget.flexible;
    }

    final Widget fixed = SizedBox(
      width: _isHorizontal ? _size : null,
      height: _isHorizontal ? null : _size,
      child: widget.fixed,
    );
    final Widget flexible = Expanded(child: widget.flexible);
    final List<Widget> children = <Widget>[
      _isFixedLeading ? fixed : flexible,
      _buildDivider(),
      _isFixedLeading ? flexible : fixed,
    ];

    if (_isHorizontal) {
      return Row(children: children);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: children,
    );
  }

  Widget _buildDivider() {
    return MouseRegion(
      cursor: _isHorizontal
          ? SystemMouseCursors.resizeLeftRight
          : SystemMouseCursors.resizeUpDown,
      onEnter: (_) => _setDividerHighlight(true),
      onExit: (_) => _setDividerHighlight(false),
      child: DragEditable(
        handleRadius: 0,
        onStartUpdatePosition: _onStartUpdatePosition,
        onUpdate: _onUpdateSize,
        onUpdateEnd: (_) => _setDividerHighlight(false),
        child: Padding(
          padding: _isHorizontal
              ? const EdgeInsets.symmetric(horizontal: 4)
              : const EdgeInsets.symmetric(vertical: 4),
          child: Divider(
            direction: _isHorizontal ? Axis.vertical : Axis.horizontal,
            style: DividerThemeData(
              horizontalMargin: EdgeInsets.zero,
              verticalMargin: EdgeInsets.zero,
              decoration: _isDividerHighlighted
                  ? BoxDecoration(color: Colors.blue)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  void _onStartUpdatePosition(TapDragStartDetails detail) {
    _dragStartPosition = detail.globalPosition;
    _dragStartSize = _size;
  }

  void _onUpdateSize(TapDragUpdateDetails detail) {
    final Offset dragOffset = detail.globalPosition - _dragStartPosition;
    final double delta = _isHorizontal ? dragOffset.dx : dragOffset.dy;
    final double signedDelta = _isFixedLeading ? delta : -delta;
    final double nextSize = _clampSize(_dragStartSize + signedDelta);

    if (_size != nextSize || !_isDividerHighlighted) {
      setState(() {
        _size = nextSize;
        _isDividerHighlighted = true;
      });
    }

    _saveSizeToStorage(nextSize);
  }

  void _setDividerHighlight(bool highlight) {
    if (_isDividerHighlighted == highlight) return;
    setState(() {
      _isDividerHighlighted = highlight;
    });
  }

  double _clampSize(double size) {
    return size.clamp(widget.minSize, widget.maxSize).toDouble();
  }

  void _restoreSizeFromStorage() {
    if (_didRestoreSize || widget.restoreId == null) return;
    _didRestoreSize = true;

    final Object? saved = PageStorage.maybeOf(
      context,
    )?.readState(context, identifier: widget.restoreId);
    if (saved is num) {
      _size = _clampSize(saved.toDouble());
    }
  }

  void _saveSizeToStorage(double size) {
    final String? restoreId = widget.restoreId;
    if (restoreId == null) return;

    PageStorage.maybeOf(
      context,
    )?.writeState(context, size, identifier: restoreId);
  }
}
