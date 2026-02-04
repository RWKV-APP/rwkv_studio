import 'package:rwkv_studio/src/node/export.dart';

class NodePrototypes {
  static List<NodePrototype> get list => [
    ...CommonNodePrototypes.list,
    llamaCppLoad,
    LoopNodePrototype.instance,
    BranchNodePrototype.instance,
  ];

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

}
