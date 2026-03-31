import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/graph/node_factory.dart';
import 'package:rwkv_studio/src/ui/flow/_example.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

part 'node_flow_event.dart';

part 'node_flow_state.dart';

typedef NodeFlowCanvasController = NodeFlowController<String, dynamic>;
typedef NodeFlowCanvasGraph = NodeGraph<String, dynamic>;
typedef NodeFlowCanvasNode = Node<String>;
typedef NodeFlowCanvasConnection = Connection<dynamic>;
typedef NodeFlowCanvasEvents = NodeFlowEvents<String, dynamic>;
typedef NodeFlowCanvasConnectionEvents = ConnectionEvents<String, dynamic>;
typedef NodeFlowCanvasConnectionCompleteContext =
    ConnectionCompleteContext<String>;

extension Ext on BuildContext {
  NodeFlowBloc get nodeFlow => read<NodeFlowBloc>();
}

class NodeFlowBloc extends Bloc<NodeFlowEvent, NodeFlowState> {
  final NodeFlowCanvasController controller;
  final uuid = const Uuid();
  bool _started = false;

  NodeFlowBloc()
    : controller = NodeFlowCanvasController(
        config: NodeFlowConfig(showAttribution: false),
      ),
      super(NodeFlowState.initial()) {
    on<NodeFlowEditorReady>(_onEditorReady);
    on<NodeFlowStarted>(_onStarted);
    on<NodeFlowGraphReplaced>(_onGraphReplaced);
    on<NodeFlowGraphCleared>(_onGraphCleared);
    on<NodeFlowViewportCentered>(_onViewportCentered);
    on<NodeFlowViewportFitRequested>(_onViewportFitRequested);
    on<NodeFlowSelectionCleared>(_onSelectionCleared);
    on<NodeFlowStateRefreshed>(_onStateRefreshed);
    on<NodeFlowThemeChanged>(_onThemeChanged);
    on<NodeFlowToggleDebug>((event, emit) {
      emit(state.copyWith(showDebugPane: !state.showDebugPane));
    });
    on<NodeFlowNodeAdded>((event, emit) {
      final node = NodeFactory.create(
        event.type,
        position: event.position,
        data: '',
      );
      controller.addNode(node);
      emit(_snapshot());
    });
    on<NodeFlowGraphImportFile>((event, emit) {
      final graph = NodeGraph.fromJson(
        event.raw,
        (c) => c.toString(),
        (c) => c.toString(),
      );
      controller.loadGraph(graph);
      emit(_snapshot(status: NodeFlowStatus.ready));
    });

    add(const NodeFlowStarted(graph: null, force: false));
  }

  void replaceGraph(
    NodeFlowCanvasGraph graph, {
    bool centerViewport = false,
    bool fitToView = false,
  }) {
    add(
      NodeFlowGraphReplaced(
        graph: graph,
        centerViewport: centerViewport,
        fitToView: fitToView,
      ),
    );
  }

  void clearGraph() => add(const NodeFlowGraphCleared());

  void centerViewport() => add(const NodeFlowViewportCentered());

  void fitToView() => add(const NodeFlowViewportFitRequested());

  void clearSelection() => add(const NodeFlowSelectionCleared());

  void syncController() => add(const NodeFlowStateRefreshed());

  NodeFlowCanvasGraph exportGraph() => controller.exportGraph();

  ConnectionValidationResult validatePortLink({
    required NodeFlowCanvasNode sourceNode,
    required Port sourcePort,
    required NodeFlowCanvasNode targetNode,
    required Port targetPort,
  }) {
    if (sourceNode.id == targetNode.id && sourcePort.id == targetPort.id) {
      return const ConnectionValidationResult.deny(
        reason: 'Cannot connect a port to itself',
      );
    }

    if (!sourcePort.isOutput) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port must support output connections',
      );
    }

    if (!targetPort.isInput) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port must support input connections',
      );
    }

    if (!sourcePort.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port is not connectable',
      );
    }

    if (!targetPort.isConnectable) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port is not connectable',
      );
    }

    final duplicateExists = controller.connections.any(
      (connection) =>
          connection.sourceNodeId == sourceNode.id &&
          connection.sourcePortId == sourcePort.id &&
          connection.targetNodeId == targetNode.id &&
          connection.targetPortId == targetPort.id,
    );
    if (duplicateExists) {
      return const ConnectionValidationResult.deny(
        reason: 'Connection already exists',
      );
    }

    if (!_hasAvailableCapacity(
      port: sourcePort,
      connectionCount: controller
          .getConnectionsFromPort(sourceNode.id, sourcePort.id)
          .length,
    )) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port has maximum connections',
      );
    }

    if (!_hasAvailableCapacity(
      port: targetPort,
      connectionCount: controller
          .getConnectionsToPort(targetNode.id, targetPort.id)
          .length,
    )) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port has maximum connections',
      );
    }

    return const ConnectionValidationResult.allow();
  }

  ConnectionValidationResult validatePortLinkById({
    required String sourceNodeId,
    required String sourcePortId,
    required String targetNodeId,
    required String targetPortId,
  }) {
    final sourceNode = controller.getNode(sourceNodeId);
    if (sourceNode == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Source node not found',
      );
    }

    final targetNode = controller.getNode(targetNodeId);
    if (targetNode == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Target node not found',
      );
    }

    final sourcePort = _findPort(sourceNode, sourcePortId);
    if (sourcePort == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Source port not found',
      );
    }

    final targetPort = _findPort(targetNode, targetPortId);
    if (targetPort == null) {
      return const ConnectionValidationResult.deny(
        reason: 'Target port not found',
      );
    }

    return validatePortLink(
      sourceNode: sourceNode,
      sourcePort: sourcePort,
      targetNode: targetNode,
      targetPort: targetPort,
    );
  }

  bool canLinkPorts({
    required String sourceNodeId,
    required String sourcePortId,
    required String targetNodeId,
    required String targetPortId,
  }) {
    return validatePortLinkById(
      sourceNodeId: sourceNodeId,
      sourcePortId: sourcePortId,
      targetNodeId: targetNodeId,
      targetPortId: targetPortId,
    ).allowed;
  }

  void _onEditorReady(NodeFlowEditorReady event, Emitter<NodeFlowState> emit) {
    controller.updateTheme(state.theme);
    emit(state.copyWith(initialized: true));
  }

  Future<void> _onStarted(
    NodeFlowStarted event,
    Emitter<NodeFlowState> emit,
  ) async {
    if (_started && !event.force) {
      emit(_snapshot());
      return;
    }

    _started = true;

    if (event.graph != null) {
      controller.loadGraph(event.graph!);
    } else if (controller.nodeCount == 0 && controller.connectionCount == 0) {
      final graph = NodeGraph.fromJson(
        exampleGraphJson,
        (c) => c.toString(),
        (c) => c.toString(),
      );
      controller.loadGraph(graph);
    }

    emit(_snapshot(status: NodeFlowStatus.ready));

    controller.centerViewport();
  }

  Future<void> _onGraphReplaced(
    NodeFlowGraphReplaced event,
    Emitter<NodeFlowState> emit,
  ) async {
    controller.loadGraph(event.graph);
    emit(_snapshot(status: NodeFlowStatus.ready));
    _scheduleViewportAction(
      centerViewport: event.centerViewport,
      fitToView: event.fitToView,
    );
  }

  Future<void> _onGraphCleared(
    NodeFlowGraphCleared event,
    Emitter<NodeFlowState> emit,
  ) async {
    controller.clearGraph();
    emit(_snapshot());
  }

  Future<void> _onViewportCentered(
    NodeFlowViewportCentered event,
    Emitter<NodeFlowState> emit,
  ) async {
    controller.centerViewport();
    emit(_snapshot());
  }

  Future<void> _onViewportFitRequested(
    NodeFlowViewportFitRequested event,
    Emitter<NodeFlowState> emit,
  ) async {
    controller.fitToView();
    emit(_snapshot());
  }

  Future<void> _onSelectionCleared(
    NodeFlowSelectionCleared event,
    Emitter<NodeFlowState> emit,
  ) async {
    controller.clearSelection();
    emit(_snapshot());
  }

  Future<void> _onStateRefreshed(
    NodeFlowStateRefreshed event,
    Emitter<NodeFlowState> emit,
  ) async {
    emit(_snapshot());
  }

  void _onThemeChanged(
    NodeFlowThemeChanged event,
    Emitter<NodeFlowState> emit,
  ) async {
    logd('Theme changed: ${event.theme}, isDark: ${event.isDark}');
    emit(state.copyWith(theme: event.theme));
    var minimap = controller.getPlugin<MinimapPlugin>();
    if (minimap != null) {
      controller.config.pluginRegistry.remove(minimap.id);
      controller.removePlugin(minimap.id);
    }

    minimap = MinimapPlugin(
      visible: true,
      theme: event.isDark ? MinimapTheme.dark : MinimapTheme.light,
    );
    controller.config.pluginRegistry.register(minimap);
    controller.addPlugin(minimap);

    if (controller.isEditorInitialized) {
      controller.updateTheme(event.theme);
    }
  }

  ConnectionValidationResult _onBeforeConnectionComplete(
    NodeFlowCanvasConnectionCompleteContext context,
  ) {
    return validatePortLink(
      sourceNode: context.sourceNode,
      sourcePort: context.sourcePort,
      targetNode: context.targetNode,
      targetPort: context.targetPort,
    );
  }

  void _scheduleViewportAction({
    required bool centerViewport,
    required bool fitToView,
  }) {
    if (!centerViewport && !fitToView) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        return;
      }
      if (fitToView) {
        controller.fitToView();
      } else if (centerViewport) {
        controller.centerViewport();
      }
      syncController();
    });
  }

  NodeFlowState _snapshot({NodeFlowStatus? status}) {
    return state.copyWith(
      status: status ?? state.status,
      revision: state.revision + 1,
      nodeCount: controller.nodeCount,
      connectionCount: controller.connectionCount,
      selectedNodeIds: List.unmodifiable(controller.selectedNodeIds),
      selectedConnectionIds: List.unmodifiable(
        controller.selectedConnectionIds,
      ),
      viewport: controller.viewport,
    );
  }

  Port? _findPort(NodeFlowCanvasNode node, String portId) {
    for (final port in node.allPorts) {
      if (port.id == portId) {
        return port;
      }
    }
    return null;
  }

  bool _hasAvailableCapacity({
    required Port port,
    required int connectionCount,
  }) {
    final maxConnections = port.maxConnections;
    if (maxConnections == null) {
      return true;
    }
    return connectionCount < maxConnections;
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
