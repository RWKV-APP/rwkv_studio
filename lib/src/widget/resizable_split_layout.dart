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
  final bool autoHideDivider;

  const ResizableSplitLayout({
    super.key,
    required this.fixed,
    required this.flexible,
    required this.direction,
    required this.size,
    required this.minSize,
    required this.maxSize,
    this.restoreId,
    this.autoHideDivider = false,
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
  static const Duration _paneVisibilityDuration = Duration(milliseconds: 220);
  static const Curve _paneVisibilityCurve = Curves.easeInOutCubic;
  static const double _dividerExtent = 9;

  Offset _dragStartPosition = Offset.zero;
  late double _size;
  double _dragStartSize = 0;
  bool _isDividerHighlighted = false;
  bool _didRestoreSize = false;
  bool _enableVisibilityAnimation = false;

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  bool get _isFixedLeading => widget.flexibleAlignEnd;

  Alignment get _fixedAlignment {
    if (_isHorizontal) {
      return _isFixedLeading ? Alignment.centerLeft : Alignment.centerRight;
    }
    return _isFixedLeading ? Alignment.topCenter : Alignment.bottomCenter;
  }

  @override
  void initState() {
    super.initState();
    _size = _clampSize(widget.size);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _enableVisibilityAnimation = true;
      });
    });
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
    final Widget flexible = Expanded(child: widget.flexible);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.hideFixedWidget ? 0 : 1),
      duration: _enableVisibilityAnimation
          ? _paneVisibilityDuration
          : Duration.zero,
      curve: _paneVisibilityCurve,
      builder: (context, visibility, child) {
        final Widget fixed = _buildFixedPane(visibility, child!);
        final Widget divider = _buildDivider(visibility);
        final List<Widget> children = <Widget>[
          _isFixedLeading ? fixed : flexible,
          divider,
          _isFixedLeading ? flexible : fixed,
        ];

        if (_isHorizontal) {
          return Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: children,
        );
      },
      child: widget.fixed,
    );
  }

  Widget _buildFixedPane(double visibility, Widget child) {
    final hidden = visibility <= 0.001;

    return SizedBox(
      width: _isHorizontal ? _size * visibility : null,
      height: _isHorizontal ? null : _size * visibility,
      child: IgnorePointer(
        ignoring: hidden,
        child: Opacity(
          opacity: visibility,
          child: ClipRect(
            child: OverflowBox(
              alignment: _fixedAlignment,
              minWidth: _isHorizontal ? _size : null,
              maxWidth: _isHorizontal ? _size : null,
              minHeight: _isHorizontal ? null : _size,
              maxHeight: _isHorizontal ? null : _size,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(double visibility) {
    final hidden = visibility <= 0.001;
    final extent = _dividerExtent * visibility;

    if (_isHorizontal) {
      return SizedBox(
        width: extent,
        child: IgnorePointer(
          ignoring: hidden,
          child: Opacity(
            opacity: visibility,
            child: ClipRect(
              child: OverflowBox(
                alignment: _isFixedLeading
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                minWidth: _dividerExtent,
                maxWidth: _dividerExtent,
                child: _buildDividerContent(),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: extent,
      child: IgnorePointer(
        ignoring: hidden,
        child: Opacity(
          opacity: visibility,
          child: ClipRect(
            child: OverflowBox(
              alignment: _isFixedLeading
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              minHeight: _dividerExtent,
              maxHeight: _dividerExtent,
              child: _buildDividerContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDividerContent() {
    BoxDecoration? decor = _isDividerHighlighted
        ? BoxDecoration(color: Colors.blue)
        : null;

    if (widget.autoHideDivider && decor == null) {
      decor = const BoxDecoration(color: Colors.transparent);
    }

    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
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
              decoration: decor,
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
