import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/node_flow/node_flow_bloc.dart';
import 'package:rwkv_studio/src/graph/node_factory.dart';
import 'package:rwkv_studio/src/theme/theme.dart';
import 'package:rwkv_studio/src/theme/work_flow.dart';
import 'package:rwkv_studio/src/utils/file_util.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:rwkv_studio/src/widget/resizable_split_layout.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

part '_node_widget.dart';

part '_tool_bar.dart';

part '_viewport_cxt_menu.dart';

class FlowPage extends StatelessWidget {
  const FlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeFlowBloc, NodeFlowState>(
      buildWhen: (p, c) => p.showDebugPane != c.showDebugPane,
      builder: (context, state) {
        return ResizableSplitLayout(
          restoreId: 'node-flow-sidebar',
          fixed: Container(color: context.fluent.scaffoldBackgroundColor),
          flexibleAlignEnd: false,
          hideFixedWidget: !state.showDebugPane,
          direction: .horizontal,
          size: 400,
          minSize: 200,
          maxSize: 600,
          flexible: Stack(
            fit: .expand,
            children: [
              const _Editor(),
              Positioned(right: 0, left: 0, top: 8, child: _Toolbar()),
            ],
          ),
        );
      },
    );
  }
}

class _Editor extends StatelessWidget {
  static final FlyoutController flyoutController = FlyoutController();

  const _Editor();

  void _showCanvasContextMenu(
    BuildContext context,
    Offset screenPos,
    Offset graphPos,
  ) {
    _Editor.flyoutController.showFlyout(
      position: screenPos,
      builder: (c) => _AddNodeMenu(position: graphPos),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return FlyoutTarget(
      controller: _Editor.flyoutController,
      child: BlocBuilder<NodeFlowBloc, NodeFlowState>(
        buildWhen: (p, c) => p.theme != c.theme,
        builder: (context, state) {
          final controller = context.nodeFlow.controller;
          return NodeFlowEditor<String, dynamic>(
            controller: controller,
            theme: state.theme,
            events: NodeFlowEvents<String, dynamic>(
              onInit: () {
                logi('NodeFlowEditor widget initialized');
              },
              viewport: ViewportEvents(
                onCanvasContextMenu: (c) => _showCanvasContextMenu(
                  context,
                  controller.graphToScreen(c).offset,
                  c.offset,
                ),
              ),
              connection: ConnectionEvents(
                onConnectEnd: (node, port, pos) {
                  logd('${node?.id}, ${port?.id}, $pos');
                },
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
              if (node1.type == 'Tools') {
                //
              }
              return ConnectionStyles.bezier;
            },
            portBuilder: (ctx, node, port) {
              return PortWidget(
                port: port,
                theme: state.theme.portTheme,
                controller: controller,
                nodeId: node.id,
                isOutput: !port.isInput,
                size: port.size,
                isConnected: controller.isPortConnected(node.id, port.id),
                nodeBounds: controller.getNodeBounds(node.id)!,
              );
            },
            behavior: .design,
            nodeBuilder: (context, node) => _NodeWidget(node: node),
          );
        },
      ),
    );
  }
}
