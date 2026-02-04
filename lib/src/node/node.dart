import 'export.dart';

typedef NodeId = String;

class NodeExecution {
  final Future<NodeResult>? future;
  final Stream<NodeResult>? stream;
  final NodeResult? result;

  // Streaming: emit NodeSuccess for incremental outputs; emit NodeFail to stop.
  // NodeSuspend is only supported for non-streaming executions.
  NodeExecution({this.future, this.stream, this.result})
    : assert(future != null || stream != null || result != null);
}

class NodeExecutor {
  const NodeExecutor();

  NodeExecution execute(NodeContext ctx) {
    return NodeExecution(
      result: NodeFail(
        UnimplementedError('NodeExecutor.execute not implemented'),
      ),
    );
  }

  Future invalidateCache() async {
    //
  }
}

sealed class NodeResult {
  const NodeResult();
}

class ControlEmission {
  final String port;
  final Value? payload;

  const ControlEmission({required this.port, this.payload});
}

class NodeSuccess extends NodeResult {
  final Map<String, Value> outputs;
  final List<ControlEmission> control;

  const NodeSuccess(this.outputs, {this.control = const []});
}

class NodeSuspend extends NodeResult {
  final Future<NodeResult> resume;

  const NodeSuspend(this.resume);
}

class NodeFail extends NodeResult {
  final Object error;
  final bool retryable;

  const NodeFail(this.error, {this.retryable = false});
}

enum NodeSemantics { pure, sideEffect }

enum NodeDispatchType { sync, async, streaming }

enum NodeCacheLevel {
  none,
  // cache each session
  session,
  // cache after first run
  forever,
  duration,
}

class PolicyConfigurations {
  final int maxRetries;
  final Duration retryDelay;
  final NodeCacheLevel cachePolicy;
  final Duration cacheTtl;

  const PolicyConfigurations({
    this.maxRetries = 0,
    this.retryDelay = const Duration(seconds: 1),
    this.cachePolicy = NodeCacheLevel.session,
    this.cacheTtl = Duration.zero,
  });

  Duration delayFor(int attempt) {
    if (attempt <= 1) return retryDelay;
    return Duration(milliseconds: retryDelay.inMilliseconds * attempt);
  }
}

class NodePrototype {
  final String name;
  final String description;
  final List<SocketPrototype> inputs;
  final List<SocketPrototype> outputs;
  final List<ControlPrototype> controlInputs;
  final List<ControlPrototype> controlOutputs;

  final Duration timeout;
  final NodeSemantics semantics;
  final NodeDispatchType dispatchType;
  final PolicyConfigurations policy;
  final NodeExecutor executor;

  NodePrototype({
    required this.name,
    required this.description,
    this.inputs = const [],
    this.outputs = const [],
    this.controlInputs = const [],
    this.controlOutputs = const [],
    required this.executor,
    this.policy = const PolicyConfigurations(),
    this.dispatchType = NodeDispatchType.sync,
    this.timeout = const Duration(seconds: 10),
    this.semantics = NodeSemantics.pure,
  });

  static int _globalSeq = 0;

  Node create() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final seq = _globalSeq++;
    final nodeId = '${name}_${now}_$seq';
    var socketSeq = 0;
    return Node(
      id: nodeId,
      inputs: inputs
          .map(
            (def) => NodeInput(
              nodeId: nodeId,
              id: '${nodeId}_${def.name}_${socketSeq++}',
              prototype: def,
            ),
          )
          .toList(),
      outputs: outputs
          .map(
            (def) => NodeOutput(
              nodeId: nodeId,
              id: '${nodeId}_${def.name}_${socketSeq++}',
              prototype: def,
            ),
          )
          .toList(),
      controlInputs: controlInputs
          .map(
            (def) => NodeControlIn(
              nodeId: nodeId,
              id: '${nodeId}_${def.name}_${socketSeq++}',
              name: def.name,
            ),
          )
          .toList(),
      controlOutputs: controlOutputs
          .map(
            (def) => NodeControlOut(
              nodeId: nodeId,
              id: '${nodeId}_${def.name}_${socketSeq++}',
              name: def.name,
            ),
          )
          .toList(),
      prototype: this,
    );
  }
}

class Node {
  final NodeId id;
  final List<NodeInput> inputs;
  final List<NodeOutput> outputs;
  final List<NodeControlIn> controlInputs;
  final List<NodeControlOut> controlOutputs;
  final NodePrototype prototype;
  final Map<String, dynamic> params;

  NodeSocket getSocketById(SocketId id) =>
      outputs.firstWhere((socket) => socket.id == id);

  List<NodeSocket> get allInputs => [...inputs, ...controlInputs];

  List<NodeSocket> get allOutputs => [...outputs, ...controlOutputs];

  Node({
    required this.id,
    this.inputs = const [],
    this.outputs = const [],
    this.controlInputs = const [],
    this.controlOutputs = const [],
    required this.prototype,
    Map<String, dynamic>? params,
  }) : params = params ?? {};
}

class NodeGroupPrototype extends NodePrototype {
  NodeGroupPrototype._()
    : super(
        name: 'NodeGroup',
        description: 'NodeGroup',
        executor: const NodeExecutor(),
      );

  static NodeGroupPrototype instance = NodeGroupPrototype._();

  @override
  NodeGroup create() {
    return NodeGroup(
      id: '${name}_${DateTime.now().millisecondsSinceEpoch}',
      prototype: this,
    );
  }
}

class OutputNode extends Node {
  OutputNode({
    required super.id,
    required super.inputs,
    super.controlInputs = const [],
    super.controlOutputs = const [],
    required super.prototype,
  }) : super(outputs: const []);
}

class InputNode extends Node {
  InputNode({
    required super.id,
    required super.outputs,
    super.controlInputs = const [],
    super.controlOutputs = const [],
    required super.prototype,
  }) : super(inputs: const []);
}

enum EdgeKind { data, control }

class NodeEdge<T> {
  final String id;

  final EdgeKind kind;

  final NodeId fromNodeId;
  final SocketId fromSocket;

  final NodeId toNodeId;
  final SocketId toSocket;

  NodeEdge({
    required this.id,
    required this.kind,
    required this.fromNodeId,
    required this.toNodeId,
    required this.fromSocket,
    required this.toSocket,
  });
}

class NodeGroup extends Node {
  final Map<NodeId, Node> _nodes;
  final Map<String, NodeEdge> _edges;

  Map<NodeId, Node> get nodes => _nodes;

  Map<String, NodeEdge> get edges => _edges;

  NodeGroup({
    required super.id,
    super.inputs = const [],
    super.outputs = const [],
    super.controlInputs = const [],
    super.controlOutputs = const [],
    required super.prototype,
  }) : _nodes = {},
       _edges = {};

  void addNode(Node node) {
    _nodes[node.id] = node;
  }

  void removeNode(NodeId nodeId) {
    final node = _nodes.remove(nodeId);
    if (node == null) return;
    _edges.removeWhere((_, edge) => 
      edge.fromNodeId == nodeId || edge.toNodeId == nodeId);
  }

  void addEdge(NodeEdge edge) {
    _edges[edge.id] = edge;
  }

  void removeEdge(String edgeId) {
    _edges.remove(edgeId);
  }

  void connectData(NodeOutput output, NodeInput input) {
    final edge = NodeEdge(
      id: '${input.id}_${output.id}_${DateTime.now().millisecondsSinceEpoch}',
      fromNodeId: output.nodeId,
      toNodeId: input.nodeId,
      kind: EdgeKind.data,
      fromSocket: output.id,
      toSocket: input.id,
    );
    addEdge(edge);
  }

  void connectControl(NodeControlOut output, NodeControlIn input) {
    final fromPort = output.prototype.name;
    final toPort = input.prototype.name;
    final edge = NodeEdge(
      id: '${input.id}_${output.id}_${DateTime.now().millisecondsSinceEpoch}',
      fromNodeId: output.nodeId,
      toNodeId: input.nodeId,
      kind: EdgeKind.control,
      fromSocket: fromPort,
      toSocket: toPort,
    );
    addEdge(edge);
  }

  void disconnectInput(SocketId inputId) {
    _edges.removeWhere((_, edge) => edge.toSocket == inputId);
  }

  void disconnectOutput(SocketId outputId) {
    _edges.removeWhere((_, edge) => edge.fromSocket == outputId);
  }
}
