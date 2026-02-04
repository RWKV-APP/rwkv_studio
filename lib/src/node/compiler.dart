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
      final outNode = group.nodes[out];
      final inNode = group.nodes[in_];
      if (outNode == null) {
        throw StateError('Edge ${edge.id} references missing fromNodeId: $out');
      }
      if (inNode == null) {
        throw StateError('Edge ${edge.id} references missing toNodeId: $in_');
      }

      if (edge.kind == EdgeKind.data) {
        final hasOut = outNode.outputs.any((o) => o.id == edge.fromSocket);
        if (!hasOut) {
          throw StateError(
            'Edge ${edge.id} references missing data output: ${edge.fromSocket}',
          );
        }
        final hasIn = inNode.inputs.any((i) => i.id == edge.toSocket);
        if (!hasIn) {
          throw StateError(
            'Edge ${edge.id} references missing data input: ${edge.toSocket}',
          );
        }
        if (inDataByPort[in_]?.containsKey(edge.toSocket) ?? false) {
          throw StateError(
            'Multiple data edges for input ${edge.toSocket} on node $in_',
          );
        }
        outData[out] ??= [];
        outData[out]!.add(edge);
        inDataByPort[in_] ??= {};
        inDataByPort[in_]![edge.toSocket] = edge;
      } else {
        if (outNode.controlOutputs.isNotEmpty) {
          final outMatches = outNode.controlOutputs.any(
            (o) =>
                o.id == edge.fromSocket || o.prototype.name == edge.fromSocket,
          );
          if (!outMatches) {
            throw StateError(
              'Edge ${edge.id} references missing control output: ${edge.fromSocket}',
            );
          }
        }
        if (inNode.controlInputs.isNotEmpty) {
          final inMatches = inNode.controlInputs.any(
            (i) => i.id == edge.toSocket || i.prototype.name == edge.toSocket,
          );
          if (!inMatches) {
            throw StateError(
              'Edge ${edge.id} references missing control input: ${edge.toSocket}',
            );
          }
        }
        outControl[out] ??= [];
        outControl[out]!.add(edge);
        inControl[in_] ??= [];
        inControl[in_]!.add(edge);
      }
    }

    for (final entry in group.nodes.entries) {
      final node = entry.value;
      if (node.inputs.isEmpty && node.controlInputs.isEmpty) {
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
    // TODO: topology and cycle checks.
  }
}
