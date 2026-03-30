import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_studio/src/bloc/node_flow/node_flow_bloc.dart';
import 'package:rwkv_studio/src/graph/node_factory.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/theme/work_flow.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/widget/resizable_split_layout.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

part '_node_widget.dart';

part '_viewport_cxt_menu.dart';

class FlowPage extends StatelessWidget {
  static final FlyoutController flyoutController = FlyoutController();

  const FlowPage({super.key});

  void _showCanvasContextMenu(
    BuildContext context,
    Offset screenPos,
    Offset graphPos,
  ) {
    flyoutController.showFlyout(
      position: screenPos,
      builder: (c) => _AddNodeMenu(position: graphPos),
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
            c.offset,
          ),
        ),
        connection: ConnectionEvents(
          onConnectEnd: (node, port, pos) {
            logd('${node?.id}, ${port?.id}, $pos');
          }
        ),
        node: NodeEvents<String>(
          onSelected: (s) {
            //
          },
          onContextMenu: (s, c) {
            //
          },
        ),
      ),
      connectionStyleBuilder: (conn, node1, node2) {
        return ConnectionStyles.bezier;
      },
      portBuilder: (ctx, node, port) {
        return PortWidget(
          port: port,
          theme: theme.portTheme,
          controller: editorController,
          nodeId: node.id,
          isOutput: !port.isInput,
          size: port.size,
          isConnected: editorController.isPortConnected(node.id, port.id),
          nodeBounds: editorController.getNodeBounds(node.id)!,
        );
      },
      behavior: .design,
      nodeBuilder: (context, node) => _NodeWidget(node: node),
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
