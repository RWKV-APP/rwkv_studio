import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/batch_infer/batch_infer_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/ui/batch_infer/_setting_pannel.dart';
import 'package:rwkv_studio/src/ui/batch_infer/text_painter.dart';
import 'package:rwkv_studio/src/ui/common/model_selector_button.dart';
import 'package:rwkv_studio/src/utils/pair.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/side_bar.dart';

part '_title_bar.dart';

extension _Ext on BuildContext {
  BatchInferCubit get cubit => BlocProvider.of<BatchInferCubit>(this);
}

class BatchInferPage extends StatelessWidget {
  const BatchInferPage._();

  static Widget create() => LayoutBuilder(
    builder: (ctx, _) {
      return KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.physicalKey == PhysicalKeyboardKey.escape) {
            ctx.app.setFullScreen(false);
          }
        },
        child: const BatchInferPage._(),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .symmetric(horizontal: 12, vertical: 12),
      child: BlocBuilder<BatchInferCubit, BatchInferState>(
        buildWhen: (prev, cur) => cur.showSettingPanel != prev.showSettingPanel,
        builder: (context, state) {
          return CollapsibleSidebarLayout(
            open: state.showSettingPanel,
            sidebar: const BatchInferSettingPanel(),
            content: Column(
              mainAxisSize: .max,
              crossAxisAlignment: .stretch,
              children: [
                _TitleBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    fit: .expand,
                    children: [
                      buildGrid(context), //
                      _GridEventGesture(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildGrid(BuildContext context) {
    final textColor = context.fluent.typography.caption?.copyWith(
      fontSize: 10,
      height: 1,
      letterSpacing: 1,
    );
    return BlocBuilder<BatchInferCubit, BatchInferState>(
      buildWhen: (prev, cur) =>
          cur.responsesDisplay != prev.responsesDisplay ||
          cur.setting != prev.setting,
      builder: (context, state) {
        return CustomPaint(
          painter: GridBackgroundPainter(
            rows: state.setting.row,
            cols: state.setting.col,
          ),
          foregroundPainter: GridTailParagraphPainter(
            cells: state.responsesDisplay,
            rows: state.setting.row,
            cols: state.setting.col,
            colSpacing: 2,
            rowSpacing: 2,
            textStyle:
                textColor ??
                const TextStyle(
                  fontSize: 10,
                  height: 1,
                  letterSpacing: 1,
                  color: Colors.black,
                ),
          ),
        );
      },
    );
  }
}

class _GridEventGesture extends StatefulWidget {
  @override
  State<_GridEventGesture> createState() => _GridEventGestureState();
}

class _GridEventGestureState extends State<_GridEventGesture> {
  late BatchSizeState setting = context.cubit.state.setting;
  final controller = FlyoutController();
  bool running = false;

  Offset pointer = Offset.zero;
  Size widgetSize = Size.zero;
  Pair<int, int>? currentCell;

  void _onMove(PointerHoverEvent e) {
    pointer = e.localPosition;
    final cellW = widgetSize.width / setting.col;
    final cellH = widgetSize.height / setting.row;
    final c = (pointer.dx / cellW).floor();
    final r = (pointer.dy / cellH).floor();
    if (c != currentCell?.first || r != currentCell?.second) {
      setState(() {
        currentCell = Pair(c, r);
      });
    }
  }

  void _showRawResponse() {
    final cell = currentCell!.first + currentCell!.second * setting.col;
    final raw = context.cubit.state.responses[cell];
    controller.showFlyout(
      position: pointer,
      builder: (ctx) {
        return FlyoutContent(
          constraints: BoxConstraints(
            maxWidth: widgetSize.width / 2,
            maxHeight: widgetSize.height / 2,
          ),
          child: SelectableText(raw),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (running || currentCell == null) {
          return;
        }
        _showRawResponse();
      },
      child: MouseRegion(
        onHover: _onMove,
        onExit: (_) {
          currentCell = null;
          setState(() {});
        },
        child: BlocListener<BatchInferCubit, BatchInferState>(
          listenWhen: (prev, cur) =>
              cur.isRunning != prev.isRunning || cur.setting != prev.setting,
          listener: (context, state) {
            setState(() {
              running = state.isRunning;
              setting = state.setting;
            });
          },
          child: LayoutBuilder(
            builder: (ctx, cs) {
              widgetSize = Size(cs.maxWidth, cs.maxHeight);
              if (currentCell == null) {
                return const SizedBox();
              }
              return FlyoutTarget(
                controller: controller,
                child: CustomPaint(
                  painter: _GridHighlightPainter(
                    rows: setting.row,
                    cols: setting.col,
                    highlightRow: currentCell!.second,
                    highlightCol: currentCell!.first,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GridHighlightPainter extends CustomPainter {
  final int rows;
  final int cols;
  final int highlightRow;
  final int highlightCol;

  late final _paint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.stroke;

  _GridHighlightPainter({
    required this.rows,
    required this.cols,
    required this.highlightRow,
    required this.highlightCol,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rowHeight = size.height / rows;
    final colWidth = size.width / cols;

    final left = highlightCol * colWidth;
    final top = highlightRow * rowHeight;
    final right = (highlightCol + 1) * colWidth;
    final bottom = (highlightRow + 1) * rowHeight;
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), _paint);
  }

  @override
  bool shouldRepaint(covariant _GridHighlightPainter oldDelegate) =>
      rows != oldDelegate.rows ||
      cols != oldDelegate.cols ||
      highlightRow != oldDelegate.highlightRow ||
      highlightCol != oldDelegate.highlightCol;
}
