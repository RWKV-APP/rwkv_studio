import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DragEditRecognizer extends TapAndPanGestureRecognizer {
  int _pointer = -1;
  final Rect? dragArea;

  DragEditRecognizer({required super.debugOwner, this.dragArea});

  @override
  void handleEvent(PointerEvent event) {
    if (_pointer != -1 && _pointer != event.pointer) {
      resolve(GestureDisposition.rejected);
      return;
    }
    if (_pointer == -1 && event is PointerMoveEvent) {
      if (dragArea != null && !dragArea!.contains(event.localPosition)) {
        return;
      }
      _pointer = event.pointer;
      resolvePointer(_pointer, GestureDisposition.accepted);
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _pointer = -1;
    }
    super.handleEvent(event);
  }

  @override
  String get debugDescription => "DragEditRecognizer";
}

class DragEditable extends StatelessWidget {
  /// local offset of widget
  final ValueChanged<Offset>? onStartUpdatePosition;
  final Function(bool isRangeStart)? onStartUpdateRange;

  /// global offset
  final ValueChanged<TapDragUpdateDetails>? onUpdate;
  final VoidCallback? onUpdateEnd;
  final VoidCallback? onTap;

  final Rect? dragArea;
  final Widget child;

  bool get _endableUpdateRange => onStartUpdateRange != null;

  final double handleRadius;

  const DragEditable({
    super.key,
    this.onStartUpdatePosition,
    this.onStartUpdateRange,
    this.onUpdate,
    this.onUpdateEnd,
    this.onTap,
    this.dragArea,
    required this.child,
    required this.handleRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (!_endableUpdateRange) {
      return _wrapWithDraggable(child, isHandle: false, isRangeStart: false);
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          right: handleRadius,
          left: handleRadius,
          child: _wrapWithDraggable(
            child,
            isHandle: false,
            isRangeStart: false,
          ),
        ),
        Positioned(
          left: 0,
          width: handleRadius * 2,
          top: 0,
          bottom: 0,
          child: _wrapWithDraggable(
            _buildHandle(),
            isHandle: true,
            isRangeStart: true,
          ),
        ),
        Positioned(
          right: 0,
          width: handleRadius * 2,
          top: 0,
          bottom: 0,
          child: _wrapWithDraggable(
            _buildHandle(),
            isHandle: true,
            isRangeStart: false,
          ),
        ),
      ],
    );
  }

  Widget _wrapWithDraggable(
    Widget child, {
    required isHandle,
    required isRangeStart,
  }) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        DragEditRecognizer:
            GestureRecognizerFactoryWithHandlers<DragEditRecognizer>(
              () => DragEditRecognizer(
                debugOwner: this,
                dragArea: isHandle ? null : dragArea,
              ),
              (i) {
                i.onDragStart = (i) {
                  if (isHandle) {
                    onStartUpdateRange?.call(isRangeStart);
                  } else {
                    onStartUpdatePosition?.call(i.localPosition);
                  }
                };
                i.onDragUpdate = (i) {
                  onUpdate?.call(i);
                };
                i.onDragEnd = (i) {
                  onUpdateEnd?.call();
                };
                i.onTapUp = (i) {
                  onTap?.call();
                };
              },
            ),
      },
      child: child,
    );
  }

  Widget _buildHandle() {
    return SizedBox();
    return Visibility(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(handleRadius),
        ),
      ),
    );
  }
}
