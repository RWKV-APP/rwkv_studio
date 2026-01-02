import 'export.dart';

class RunPlan {
  final NodeId graphId;

  final Map<NodeId, Node> nodes;

  final Map<NodeId, List<NodeEdge>> outData;
  final Map<NodeId, List<NodeEdge>> outControl;

  final Map<NodeId, Map<SocketId, NodeEdge>> inDataByPort;
  final Map<NodeId, List<NodeEdge>> inControl;

  final List<NodeId> entryNodes;

  RunPlan({
    required this.nodes,
    required this.graphId,
    required this.outData,
    required this.outControl,
    required this.inDataByPort,
    required this.inControl,
    required this.entryNodes,
  });
}

class Compiler {
  Compiler();

  RunPlan compile(NodeGroup group) {
    final outData = <NodeId, List<NodeEdge>>{};
    final outControl = <NodeId, List<NodeEdge>>{};
    final inDataByPort = <NodeId, Map<String, NodeEdge>>{};
    final inControl = <NodeId, List<NodeEdge>>{};
    final entryNodes = <NodeId>[];

    for (final entry in group.edges.entries) {
      final edge = entry.value;
      final out = edge.fromNodeId;
      final in_ = edge.toNodeId;
      if (edge.kind == EdgeKind.data) {
        outData[out] ??= [];
        outData[out]!.add(edge);
        inDataByPort[in_] ??= {};
        inDataByPort[in_]![edge.toSocket] = edge;
      } else {
        outControl[out] ??= [];
        outControl[out]!.add(edge);
        inControl[in_] ??= [];
        inControl[in_]!.add(edge);
      }
    }

    for (final entry in group.nodes.entries) {
      final node = entry.value;
      if (node.inputs.isEmpty) {
        entryNodes.add(node.id);
      }
    }

    final plan = RunPlan(
      graphId: group.id,
      nodes: group.nodes,
      outData: outData,
      outControl: outControl,
      inDataByPort: inDataByPort,
      inControl: inControl,
      entryNodes: entryNodes,
    );

    _validate(plan);

    return plan;
  }

  void _validate(RunPlan plan) {
    // check topo
  }
}
