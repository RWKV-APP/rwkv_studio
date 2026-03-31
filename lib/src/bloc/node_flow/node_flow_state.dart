part of 'node_flow_bloc.dart';

enum NodeFlowStatus { initial, ready }

class NodeFlowState {
  const NodeFlowState({
    required this.status,
    required this.revision,
    required this.nodeCount,
    required this.connectionCount,
    required this.selectedNodeIds,
    required this.selectedConnectionIds,
    required this.viewport,
    required this.theme,
    required this.initialized,
    required this.showDebugPane,
  });

  final bool showDebugPane;
  final bool initialized;
  final NodeFlowStatus status;
  final int revision;
  final int nodeCount;
  final int connectionCount;
  final List<String> selectedNodeIds;
  final List<String> selectedConnectionIds;
  final GraphViewport viewport;
  final NodeFlowTheme theme;

  bool get isReady => status == NodeFlowStatus.ready;

  bool get hasSelection =>
      selectedNodeIds.isNotEmpty || selectedConnectionIds.isNotEmpty;

  factory NodeFlowState.initial() {
    return NodeFlowState(
      status: NodeFlowStatus.initial,
      revision: 0,
      nodeCount: 0,
      connectionCount: 0,
      selectedNodeIds: [],
      selectedConnectionIds: [],
      viewport: const GraphViewport(),
      theme: NodeFlowTheme.light,
      initialized: false,
      showDebugPane: false,
    );
  }

  NodeFlowState copyWith({
    NodeFlowStatus? status,
    int? revision,
    int? nodeCount,
    int? connectionCount,
    List<String>? selectedNodeIds,
    List<String>? selectedConnectionIds,
    GraphViewport? viewport,
    NodeFlowTheme? theme,
    bool? initialized,
    bool? showDebugPane,
  }) {
    return NodeFlowState(
      status: status ?? this.status,
      revision: revision ?? this.revision,
      nodeCount: nodeCount ?? this.nodeCount,
      connectionCount: connectionCount ?? this.connectionCount,
      selectedNodeIds: selectedNodeIds ?? this.selectedNodeIds,
      selectedConnectionIds:
          selectedConnectionIds ?? this.selectedConnectionIds,
      viewport: viewport ?? this.viewport,
      theme: theme ?? this.theme,
      initialized: initialized ?? this.initialized,
      showDebugPane: showDebugPane ?? this.showDebugPane,
    );
  }
}
