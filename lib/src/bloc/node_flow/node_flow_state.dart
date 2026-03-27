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
  });

  final NodeFlowStatus status;
  final int revision;
  final int nodeCount;
  final int connectionCount;
  final List<String> selectedNodeIds;
  final List<String> selectedConnectionIds;
  final GraphViewport viewport;

  bool get isReady => status == NodeFlowStatus.ready;

  bool get hasSelection =>
      selectedNodeIds.isNotEmpty || selectedConnectionIds.isNotEmpty;

  factory NodeFlowState.initial() {
    return const NodeFlowState(
      status: NodeFlowStatus.initial,
      revision: 0,
      nodeCount: 0,
      connectionCount: 0,
      selectedNodeIds: [],
      selectedConnectionIds: [],
      viewport: GraphViewport(),
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
    );
  }
}
