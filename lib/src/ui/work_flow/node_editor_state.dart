part of 'node_editor_cubit.dart';

class EdgeState {
  final String id;
  final NodeId from;
  final NodeId to;
  final Color color;
  final String fromSocket;
  final String toSocket;

  EdgeState({
    required this.from,
    required this.to,
    required this.color,
    required this.fromSocket,
    required this.toSocket,
  }) : id = '${from}_${to}_${fromSocket}_$toSocket';

  EdgeState copyWith({
    NodeId? from,
    NodeId? to,
    Color? color,
    String? fromSocket,
    String? toSocket,
  }) {
    return EdgeState(
      from: from ?? this.from,
      to: to ?? this.to,
      color: color ?? this.color,
      fromSocket: fromSocket ?? this.fromSocket,
      toSocket: toSocket ?? this.toSocket,
    );
  }
}

class NodeCardState {
  final String id;
  final Node node;
  final Rect bounds;

  Rect get hitTestBounds => bounds.inflate(20);

  NodeCardState({required this.node, required this.bounds}) : id = node.id;

  Map<NodeSocket, Offset> getSocketPositions(bool isInput) {
    final result = <NodeSocket, Offset>{};
    int index = 1;
    final sockets = isInput ? node.inputs : node.outputs;
    for (final socket in sockets) {
      double dx = 0;
      double dy = 0;
      if (isInput) {
        dx = 0;
      } else {
        dx = bounds.width;
      }
      dy = nodeHeaderHeight + (nodeSocketSpacing + nodeSocketSize / 2) * index;
      result[socket] = bounds.topLeft + Offset(dx, dy);
      index++;
    }
    return result;
  }

  Offset getInputPosition(SocketId socketId) {
    final socket = node.inputs.firstWhere((s) => s.id == socketId);
    return getSocketPosition(socket);
  }

  Offset getOutputPosition(SocketId socketId) {
    final socket = node.outputs.firstWhere((s) => s.id == socketId);
    return getSocketPosition(socket);
  }

  Offset getSocketPosition(NodeSocket socket) {
    double dx = 0;
    double dy = 0;
    int index = 0;
    if (socket is NodeInput) {
      dx = nodeSocketSize / 2;
      index = node.inputs.indexOf(socket) + 1;
    } else if (socket is NodeOutput) {
      dx = bounds.size.width - nodeSocketSize / 2;
      index = node.outputs.indexOf(socket) + 1;
    } else {
      throw UnimplementedError();
    }
    dy = getSocketDy(index);
    return bounds.topLeft + Offset(dx, dy);
  }

  double getSocketDy(int index) {
    double dy = 0;
    dy += nodeHeaderHeight;
    dy += (nodeSocketSpacing + nodeSocketSize) * index + 1;
    dy -= nodeSocketSize / 2;
    return dy;
  }

  Offset getSocketPositionFromIndex(int index, NodeSocket socket) {
    double dx = 0;
    double dy = 0;
    if (socket is NodeInput) {
      dx = nodeSocketSize / 2;
      index = node.inputs.indexOf(socket) + 1;
    } else if (socket is NodeOutput) {
      dx = bounds.size.width - nodeSocketSize / 2;
      index = node.outputs.indexOf(socket) + 1;
    } else {
      throw UnimplementedError();
    }
    dy += nodeHeaderHeight;
    dy += (nodeSocketSpacing + nodeSocketSize) * index;
    dy -= nodeSocketSize / 2;
    return bounds.topLeft + Offset(dx, dy);
  }

  static String _newId() => '${DateTime.now().millisecondsSinceEpoch}';

  NodeCardState copyWith({Node? node, Rect? bounds}) {
    return NodeCardState(
      node: node ?? this.node,
      bounds: bounds ?? this.bounds,
    );
  }
}

class EdgeEditingState {
  final String fromNodeId;
  final SocketId fromSocket;
  final String toNodeId;
  final SocketId toSocket;
  final Offset fromPos;
  final Offset toPos;
  final Color color;
  final bool output2input;

  bool get isValid => toSocket != '' && toNodeId != '';

  static final empty = EdgeEditingState(
    fromNodeId: '',
    fromPos: Offset.zero,
    fromSocket: '',
    toNodeId: '',
    toSocket: '',
    toPos: Offset.zero,
    color: Colors.black,
    output2input: false,
  );

  EdgeEditingState({
    required this.output2input,
    required this.fromNodeId,
    required this.fromSocket,
    required this.toNodeId,
    required this.toSocket,
    required this.fromPos,
    required this.toPos,
    required this.color,
  });

  EdgeEditingState copyWith({
    Offset? fromPos,
    String? fromNodeId,
    String? fromSocket,
    String? toNodeId,
    String? toSocket,
    Offset? toPos,
    Color? color,
  }) {
    return EdgeEditingState(
      fromPos: fromPos ?? this.fromPos,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      fromSocket: fromSocket ?? this.fromSocket,
      toNodeId: toNodeId ?? this.toNodeId,
      toSocket: toSocket ?? this.toSocket,
      toPos: toPos ?? this.toPos,
      color: color ?? this.color,
      output2input: output2input,
    );
  }
}

class NodeEditorState {
  final GlobalKey keyCanvas;
  final EdgeEditingState editingEdge;
  final NodeGroup group;
  final Map<String, NodeCardState> cards;
  final Map<String, EdgeState> edges;

  NodeEditorState({
    required this.keyCanvas,
    required this.editingEdge,
    required this.group,
    required this.cards,
    required this.edges,
  });

  factory NodeEditorState.initial() {
    return NodeEditorState(
      editingEdge: EdgeEditingState.empty,
      keyCanvas: GlobalKey(),
      group: NodeGroupPrototype.instance.create(),
      cards: {},
      edges: {},
    );
  }

  NodeEditorState copyWith({
    EdgeEditingState? editingEdge,
    NodeGroup? group,
    Map<String, NodeCardState>? cards,
    Map<String, EdgeState>? edges,
  }) {
    return NodeEditorState(
      keyCanvas: keyCanvas,
      editingEdge: editingEdge ?? this.editingEdge,
      group: group ?? this.group,
      cards: cards ?? this.cards,
      edges: edges ?? this.edges,
    );
  }
}
