import 'dart:async';

import 'package:rwkv_studio/src/node/export.dart';

class ConstExecutor extends NodeExecutor {
  final int value;

  ConstExecutor(this.value);

  @override
  NodeExecution execute(NodeContext ctx) {
    final params = ctx.getValue('params') as Map<String, dynamic>;
    final outId = params['outId'] as String;
    return NodeExecution(
      result: NodeSuccess({
        outId: Value(data: value, type: NodeDataType.int, meta: null),
      }),
    );
  }
}

class StartExecutor extends NodeExecutor {
  final int value;
  final String controlPort;

  StartExecutor(this.value, this.controlPort);

  @override
  NodeExecution execute(NodeContext ctx) {
    final params = ctx.getValue('params') as Map<String, dynamic>;
    final outId = params['outId'] as String;

    return NodeExecution(
      result: NodeSuccess(
        {outId: Value(data: value, type: NodeDataType.int, meta: null)},
        control: [ControlEmission(port: controlPort)],
      ),
    );
  }
}

class AddExecutor extends NodeExecutor {
  @override
  NodeExecution execute(NodeContext ctx) {
    final inputs = ctx.getValue('inputs') as Map<String, Value>;
    final params = ctx.getValue('params') as Map<String, dynamic>;
    final aId = params['aId'] as String;
    final bId = params['bId'] as String;
    final outId = params['outId'] as String;
    final controlPort = params['controlPort'] as String;

    final a = inputs[aId]?.data as int? ?? 0;
    final b = inputs[bId]?.data as int? ?? 0;

    return NodeExecution(
      result: NodeSuccess(
        {outId: Value(data: a + b, type: NodeDataType.int, meta: null)},
        control: [ControlEmission(port: controlPort)],
      ),
    );
  }
}

class StreamPrinterExecutor extends NodeExecutor {
  @override
  NodeExecution execute(NodeContext ctx) {
    final inputs = ctx.getValue('inputs') as Map<String, Value>;
    final params = ctx.getValue('params') as Map<String, dynamic>;
    final inId = params['inId'] as String;
    final outId = params['outId'] as String;
    final base = inputs[inId]?.data as int? ?? 0;

    final stream = Stream<NodeResult>.fromIterable(
      List.generate(
        3,
        (i) => NodeSuccess({
          outId: Value(data: base + i, type: NodeDataType.int, meta: null),
        }),
      ),
    );

    return NodeExecution(stream: stream);
  }
}

void logEvent(TelemetryEvent event) {
  switch (event) {
    case NodeStartEvent e:
      print('start ${e.nodeId} attempt=${e.attempt}');
    case NodeSuccessEvt e:
      final streamInfo = e.streaming ? ' stream#${e.streamIndex}' : '';
      print('success ${e.nodeId}$streamInfo');
    case NodeSuspendEvt e:
      print('suspend ${e.nodeId}');
    case NodeResumeEvt e:
      print('resume ${e.nodeId}');
    case NodeFailEvt e:
      print('fail ${e.nodeId} error=${e.error}');
    case NodeEndEvent e:
      print('end ${e.nodeId} ok=${e.success}');
  }
}

Future<void> main() async {
  const controlPort = 'next';

  final startProto = NodePrototype(
    name: 'Start',
    description: 'Entry node',
    executor: StartExecutor(1, controlPort),
    inputs: const [],
    outputs: [
      SocketPrototype(name: 'out', description: 'Out', type: NodeDataType.int),
    ],
  );

  final constProto = NodePrototype(
    name: 'Const',
    description: 'Constant node',
    executor: ConstExecutor(2),
    inputs: const [],
    outputs: [
      SocketPrototype(name: 'out', description: 'Out', type: NodeDataType.int),
    ],
  );

  final addProto = NodePrototype(
    name: 'Add',
    description: 'Add two numbers',
    executor: AddExecutor(),
    inputs: [
      SocketPrototype(
        name: 'a',
        description: 'Left',
        type: NodeDataType.int,
        required: true,
      ),
      SocketPrototype(
        name: 'b',
        description: 'Right',
        type: NodeDataType.int,
        required: true,
      ),
    ],
    outputs: [
      SocketPrototype(name: 'sum', description: 'Sum', type: NodeDataType.int),
    ],
  );

  final streamProto = NodePrototype(
    name: 'Stream',
    description: 'Streaming node',
    executor: StreamPrinterExecutor(),
    dispatchType: NodeDispatchType.streaming,
    inputs: [
      SocketPrototype(
        name: 'value',
        description: 'Value',
        type: NodeDataType.int,
        required: true,
      ),
    ],
    outputs: [
      SocketPrototype(name: 'out', description: 'Out', type: NodeDataType.int),
    ],
  );

  final startNode = startProto.create();
  startNode.params['outId'] = startNode.outputs[0].id;

  final constNode = constProto.create();
  constNode.params['outId'] = constNode.outputs[0].id;

  final addNode = addProto.create();
  addNode.params['aId'] = addNode.inputs[0].id;
  addNode.params['bId'] = addNode.inputs[1].id;
  addNode.params['outId'] = addNode.outputs[0].id;
  addNode.params['controlPort'] = controlPort;

  final streamNode = streamProto.create();
  streamNode.params['inId'] = streamNode.inputs[0].id;
  streamNode.params['outId'] = streamNode.outputs[0].id;

  final group = NodeGroupPrototype.instance.create();
  group.addNode(startNode);
  group.addNode(constNode);
  group.addNode(addNode);
  group.addNode(streamNode);

  group.addEdge(
    NodeEdge(
      id: 'e_start_add',
      kind: EdgeKind.data,
      fromNodeId: startNode.id,
      toNodeId: addNode.id,
      fromSocket: startNode.outputs[0].id,
      toSocket: addNode.inputs[0].id,
    ),
  );
  group.addEdge(
    NodeEdge(
      id: 'e_const_add',
      kind: EdgeKind.data,
      fromNodeId: constNode.id,
      toNodeId: addNode.id,
      fromSocket: constNode.outputs[0].id,
      toSocket: addNode.inputs[1].id,
    ),
  );
  group.addEdge(
    NodeEdge(
      id: 'e_add_stream',
      kind: EdgeKind.data,
      fromNodeId: addNode.id,
      toNodeId: streamNode.id,
      fromSocket: addNode.outputs[0].id,
      toSocket: streamNode.inputs[0].id,
    ),
  );

  group.addEdge(
    NodeEdge(
      id: 'c_start_add',
      kind: EdgeKind.control,
      fromNodeId: startNode.id,
      toNodeId: addNode.id,
      fromSocket: controlPort,
      toSocket: 'go',
    ),
  );
  group.addEdge(
    NodeEdge(
      id: 'c_add_stream',
      kind: EdgeKind.control,
      fromNodeId: addNode.id,
      toNodeId: streamNode.id,
      fromSocket: controlPort,
      toSocket: 'go',
    ),
  );

  final engine = NodeEngine.def();
  final handle = engine.run(group);
  handle.subscribe(logEvent);
  final result = await handle.done;
  print('run done ok=${result.ok} error=${result.error}');
}
