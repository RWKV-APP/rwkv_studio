import 'export.dart';

class StartNodePrototype extends NodePrototype {
  StartNodePrototype._({
    super.name = 'Start',
    super.description = 'Start',
    required super.controlOutputs,
    required super.executor,
  });

  static StartNodePrototype instance = StartNodePrototype._(
    controlOutputs: [ControlPrototype(name: 'entry')],
    executor: const NodeExecutor(),
  );
}

class LoopNodePrototype extends NodePrototype {
  LoopNodePrototype._()
    : super(
        name: 'Loop',
        description: 'Loop',
        executor: const NodeExecutor(),
      );

  static LoopNodePrototype instance = LoopNodePrototype._();
}

class BranchNodePrototype extends NodePrototype {
  BranchNodePrototype._({
    super.name = 'Branch',
    super.description = 'Branch',
    required super.inputs,
    required super.controlInputs,
    required super.controlOutputs,
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
    controlInputs: [ControlPrototype(name: 'in')],
    controlOutputs: [
      ControlPrototype(name: 'true'),
      ControlPrototype(name: 'false'),
    ],
    executor: const NodeExecutor(),
  );
}
