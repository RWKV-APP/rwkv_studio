import 'dart:convert';
import 'dart:math';

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

part '_viewport_cxt_menu.dart';

class FlowPage extends StatelessWidget {
  const FlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResizableSplitLayout(
      restoreId: 'node-flow-sidebar',
      fixed: Container(color: context.fluent.scaffoldBackgroundColor),
      flexibleAlignEnd: false,
      hideFixedWidget: false,
      direction: .horizontal,
      size: 400,
      minSize: 200,
      maxSize: 600,
      flexible: Stack(
        fit: .expand,
        children: [
          const _Editor(),
          Positioned(
            right: 8,
            top: 8,
            child: Card(
              padding: const .symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: .min,
                children: [
                  IconButton(
                    icon: const Icon(FluentIcons.focus_view),
                    onPressed: () {
                      context.nodeFlow.controller.centerViewport();
                    },
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.folder_open),
                    onPressed: () async {
                      final file = await FileUtils.openFileString(
                        extension: ".json",
                      ).withToast(context);
                      if (file != null && context.mounted) {
                        context.nodeFlow.add(
                          NodeFlowGraphImportFile(jsonDecode(file)),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.download_document),
                    onPressed: () {
                      final graph = context.nodeFlow.exportGraph();
                      final json = graph.toJsonString();
                      FileUtils.saveFileString(
                        content: json,
                        extension: ".json",
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(FluentIcons.play, color: Colors.green.lightest),
                    onPressed: () {
                      //
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    flyoutController.showFlyout(
      position: screenPos,
      builder: (c) => _AddNodeMenu(position: graphPos),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final controller = ctx.nodeFlow.controller;
    return FlyoutTarget(
      controller: flyoutController,
      child: BlocBuilder<NodeFlowBloc, NodeFlowState>(
        buildWhen: (p, c) => p.theme != c.theme,
        builder: (context, state) {
          return NodeFlowEditor<String, dynamic>(
            controller: controller,
            theme: state.theme,
            events: NodeFlowEvents<String, dynamic>(
              onInit: () {
                context.nodeFlow.add(const NodeFlowEditorReady());
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
