import 'export.dart';

class StartNodePrototype extends NodePrototype {
  StartNodePrototype._({
    super.name = 'Start',
    super.description = 'Start',
    required super.inputs,
    required super.outputs,
    required super.executor,
  });

  static StartNodePrototype instance = StartNodePrototype._(
    inputs: [],
    outputs: [ControlPrototype(name: 'entry')],
    executor: NodeExecutor(),
  );
}

class LoopNodePrototype extends NodePrototype {
  LoopNodePrototype._({
    super.name = 'Loop',
    super.description = 'Loop',
    required super.inputs,
    required super.outputs,
    required super.executor,
  });

  static LoopNodePrototype instance = LoopNodePrototype._(
    inputs: [],
    outputs: [],
    executor: NodeExecutor(),
  );
}

class BranchNodePrototype extends NodePrototype {
  BranchNodePrototype._({
    super.name = 'Branch',
    super.description = 'Branch',
    required super.inputs,
    required super.outputs,
    required super.executor,
  });

  static BranchNodePrototype instance = BranchNodePrototype._(
    inputs: [
      SocketPrototype(
        name: 'condition',
        description: '',
        type: NodeDataType.bool,
      ),
    ],
    outputs: [
      SocketPrototype(name: 'true', description: '', type: NodeDataType.any),
      SocketPrototype(name: 'false', description: '', type: NodeDataType.any),
    ],
    executor: NodeExecutor(),
  );
}
