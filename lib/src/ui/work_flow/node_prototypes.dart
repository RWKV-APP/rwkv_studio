import 'package:rwkv_studio/src/node/export.dart';

class NodePrototypes {
  static List<NodePrototype> get list => [
    toStringNodeProto,
    addNodeProto, //
    multiplyNodeProto,
    llamaCppLoad,
    LoopNodePrototype.instance,
    BranchNodePrototype.instance,
  ];

  static final toStringNodeProto = NodePrototype(
    name: 'ToString',
    description: 'description',
    inputs: [
      SocketPrototype(name: 'input', description: '', type: NodeDataType.int),
    ],
    outputs: [
      SocketPrototype(
        name: 'output',
        description: '',
        type: NodeDataType.string,
      ),
    ],
    executor: const NodeExecutor(),
  );

  static final decodeParam = NodePrototype(
    name: 'DecodeParam',
    description: 'description',
    inputs: [
      SocketPrototype(
        name: 'input',
        description: '',
        type: NodeDataType.string,
      ),
    ],
    outputs: [
      SocketPrototype(
        name: 'output',
        description: '',
        type: NodeDataType.string,
      ),
    ],
    executor: const NodeExecutor(),
  );

  static final llamaCppLoad = NodePrototype(
    name: 'llama.cpp load',
    description: '',
    inputs: [
      SocketPrototype(
        name: 'model path',
        description: '',
        type: NodeDataType.string,
      ),
      SocketPrototype(
        name: 'sampler',
        description: '',
        type: NodeDataType.string,
      ),
      SocketPrototype(
        name: 'device',
        description: '',
        type: NodeDataType.string,
      ),
    ],
    outputs: [
      SocketPrototype(name: 'model', description: '', type: NodeDataType.any),
    ],
    executor: const NodeExecutor(),
  );

  static final addNodeProto = NodePrototype(
    name: 'Add',
    description: 'description',
    inputs: [
      SocketPrototype(name: 'a', description: '', type: NodeDataType.int),
      SocketPrototype(name: 'b', description: '', type: NodeDataType.int),
    ],
    outputs: [
      SocketPrototype(name: 'result', description: '', type: NodeDataType.int),
    ],
    executor: const NodeExecutor(),
  );

  static final multiplyNodeProto = NodePrototype(
    name: 'Multiply',
    description: 'description',
    inputs: [
      SocketPrototype(name: 'a', description: '', type: NodeDataType.int),
      SocketPrototype(name: 'b', description: '', type: NodeDataType.int),
    ],
    outputs: [
      SocketPrototype(name: 'result', description: '', type: NodeDataType.int),
    ],
    executor: const NodeExecutor(),
  );
}
