import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/node_flow/node_flow_bloc.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/theme/work_flow.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/widget/resizable_split_layout.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

part '_viewport_cxt_menu.dart';

part '_node_widget.dart';

class FlowPage extends StatelessWidget {
  static final FlyoutController flyoutController = FlyoutController();

  const FlowPage({super.key});

  void _showCanvasContextMenu(BuildContext context, Offset position) {
    flyoutController.showFlyout(
      position: position,
      builder: (c) => _AddNodeMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = context.theme.brightness;
    final isDark = brightness == Brightness.dark;
    final theme = isDark ? WorkFlowTheme.darkTheme : WorkFlowTheme.lightTheme;
    final editorController = context.nodeFlow.controller;

    final editor = NodeFlowEditor<String, dynamic>(
      controller: editorController,
      theme: theme,
      events: NodeFlowEvents<String, dynamic>(
        viewport: ViewportEvents(
          onCanvasContextMenu: (c) => _showCanvasContextMenu(
            context,
            editorController.graphToScreen(c).offset,
          ),
        ),
        node: NodeEvents<String>(
          onSelected: (s) {
            logd('==');
          },
          onContextMenu: (s, c) {
            logd('==');
          },
        ),
      ),
      labelBuilder:
          (
            BuildContext context,
            Connection connection,
            ConnectionLabel label,
            Rect position,
            VoidCallback? onTap,
          ) {
            return const Text('1', style: TextStyle(fontSize: 12));
          },
      behavior: .design,
      nodeBuilder: (context, node) => NodeWidget(node: node),
    );

    return ResizableSplitLayout(
      restoreId: 'node-flow-sidebar',
      fixed: Container(color: context.fluent.scaffoldBackgroundColor),
      flexibleAlignEnd: false,
      hideFixedWidget: true,
      direction: .horizontal,
      size: 400,
      minSize: 200,
      maxSize: 600,
      flexible: Stack(
        fit: .expand,
        children: [FlyoutTarget(controller: flyoutController, child: editor)],
      ),
    );
  }
}
