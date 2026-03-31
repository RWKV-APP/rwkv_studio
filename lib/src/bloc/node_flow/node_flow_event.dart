part of 'node_flow_bloc.dart';

sealed class NodeFlowEvent {
  const NodeFlowEvent();
}

final class NodeFlowStarted extends NodeFlowEvent {
  const NodeFlowStarted({this.graph, this.force = false});

  final NodeFlowCanvasGraph? graph;
  final bool force;
}

final class NodeFlowGraphReplaced extends NodeFlowEvent {
  const NodeFlowGraphReplaced({
    required this.graph,
    this.centerViewport = false,
    this.fitToView = false,
  });

  final NodeFlowCanvasGraph graph;
  final bool centerViewport;
  final bool fitToView;
}

final class NodeFlowGraphImportFile extends NodeFlowEvent {
  final Map<String, dynamic> raw;

  const NodeFlowGraphImportFile(this.raw);
}

final class NodeFlowGraphCleared extends NodeFlowEvent {
  const NodeFlowGraphCleared();
}

final class NodeFlowViewportCentered extends NodeFlowEvent {
  const NodeFlowViewportCentered();
}

final class NodeFlowViewportFitRequested extends NodeFlowEvent {
  const NodeFlowViewportFitRequested();
}

final class NodeFlowSelectionCleared extends NodeFlowEvent {
  const NodeFlowSelectionCleared();
}

final class NodeFlowStateRefreshed extends NodeFlowEvent {
  const NodeFlowStateRefreshed();
}

final class NodeFlowNodeAdded extends NodeFlowEvent {
  final Offset position;
  final String type;

  const NodeFlowNodeAdded(this.position, this.type);
}
