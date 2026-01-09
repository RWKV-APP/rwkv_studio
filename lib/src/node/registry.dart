import 'export.dart';

class Registry {
  final List<NodePrototype> nodes = [];
  final List<NodeSocket> sockets = [];
  final List<NodeDataType> types = [];

  void registerNode(NodePrototype node) {
    nodes.add(node);
  }

  void registerSocket(NodeSocket socket) {
    sockets.add(socket);
  }

  void registerType(NodeDataType type) {
    types.add(type);
  }

  bool isSocketLinkable(NodeSocket from, NodeSocket to) {
    final type1 = from.prototype.type.id;
    final type2 = to.prototype.type.id;
    if (type1 == type2) {
      return true;
    }
    return false;
  }
}

void test() {
  final registry = Registry();
  final context = NodeContext();

  final startDef = NodePrototype(
    executor: NodeExecutor(),
    name: 'Start',
    description: 'Start node',
    inputs: [
      //
    ],
    outputs: [
      SocketPrototype(
        name: 'output',
        description: 'Output',
        type: NodeDataType.int,
      ),
    ],
  );

  final testDef = NodePrototype(
    name: 'Math.add',
    description: 'Add two numbers',
    executor: NodeExecutor(),
    inputs: [
      SocketPrototype(
        name: 'a',
        description: 'First number',
        type: NodeDataType.int,
      ),
      SocketPrototype(
        name: 'b',
        description: 'Second number',
        type: NodeDataType.int,
      ),
    ],
    outputs: [
      SocketPrototype(
        name: 'result',
        description: 'Result',
        type: NodeDataType.int,
      ),
    ],
  );

  registry.registerNode(testDef);

  final node1 = testDef.create();
  final node2 = testDef.create();

  final group = NodeGroupPrototype.instance.create();
  group.addNode(node1);
  group.addNode(node2);
  group.connect(node1.outputs[0], node2.inputs[0]);

  final engine = NodeEngine.def();
  engine.run(group);
}
