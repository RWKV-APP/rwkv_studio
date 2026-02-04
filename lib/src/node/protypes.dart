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
        inputs: [
          SocketPrototype(
            name: 'count',
            description: 'Iteration count',
            type: NodeDataType.int,
            required: true,
          ),
          SocketPrototype(
            name: 'value',
            description: 'Initial value',
            type: NodeDataType.int,
            required: true,
          ),
        ],
        outputs: [
          SocketPrototype(
            name: 'value',
            description: 'Final value',
            type: NodeDataType.int,
          ),
        ],
        executor: const LoopExecutor(),
      );

  static LoopNodePrototype instance = LoopNodePrototype._();
}

class _ConstExecutor extends NodeExecutor {
  const _ConstExecutor();

  @override
  NodeExecution execute(NodeContext ctx) {
    final node = ctx.getValue('node') as Node;
    final params = ctx.getValue('params') as Map<String, dynamic>;
    final raw = params['value'];
    final type = params['type'] as NodeDataType? ?? NodeDataType.any;
    final value = raw is Value ? raw : Value(data: raw, type: type, meta: null);
    return NodeExecution(
      result: NodeSuccess({node.outputs[0].id: value}),
    );
  }
}

class _ArithmeticIntExecutor extends NodeExecutor {
  const _ArithmeticIntExecutor();

  @override
  NodeExecution execute(NodeContext ctx) {
    final node = ctx.getValue('node') as Node;
    final inputs = ctx.getValue('inputs') as Map<String, Value>;
    final a = inputs[node.inputs[0].id]?.data as int? ?? 0;
    final b = inputs[node.inputs[1].id]?.data as int? ?? 0;
    final op = inputs[node.inputs[2].id]?.data as String? ?? '+';

    int result;
    switch (op) {
      case '+':
        result = a + b;
      case '-':
        result = a - b;
      case '*':
        result = a * b;
      case '/':
        if (b == 0) {
          return NodeExecution(
            result: NodeFail(StateError('Division by zero')),
          );
        }
        result = a ~/ b;
      default:
        return NodeExecution(
          result: NodeFail(StateError('Unsupported operator: $op')),
        );
    }

    return NodeExecution(
      result: NodeSuccess({
        node.outputs[0].id: Value(
          data: result,
          type: NodeDataType.int,
          meta: null,
        ),
      }),
    );
  }
}

class _BoolOpExecutor extends NodeExecutor {
  const _BoolOpExecutor();

  @override
  NodeExecution execute(NodeContext ctx) {
    final node = ctx.getValue('node') as Node;
    final inputs = ctx.getValue('inputs') as Map<String, Value>;
    final a = inputs[node.inputs[0].id]?.data;
    final b = inputs[node.inputs[1].id]?.data;
    final condition = inputs[node.inputs[2].id]?.data as String? ?? '==';

    bool result;
    switch (condition) {
      case '==':
        result = a == b;
      case '!=':
        result = a != b;
      case '>':
        result = _compare(a, b) > 0;
      case '>=':
        result = _compare(a, b) >= 0;
      case '<':
        result = _compare(a, b) < 0;
      case '<=':
        result = _compare(a, b) <= 0;
      case 'and':
        result = _asBool(a) && _asBool(b);
      case 'or':
        result = _asBool(a) || _asBool(b);
      case 'not':
        result = !_asBool(a);
      default:
        return NodeExecution(
          result: NodeFail(StateError('Unsupported condition: $condition')),
        );
    }

    return NodeExecution(
      result: NodeSuccess({
        node.outputs[0].id: Value(
          data: result,
          type: NodeDataType.bool,
          meta: null,
        ),
      }),
    );
  }

  int _compare(dynamic a, dynamic b) {
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    if (a is String && b is String) {
      return a.compareTo(b);
    }
    throw StateError(
      'Comparison requires both values to be numbers or strings',
    );
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    throw StateError('Boolean operation requires bool values');
  }
}

class _ToStringExecutor extends NodeExecutor {
  const _ToStringExecutor();

  @override
  NodeExecution execute(NodeContext ctx) {
    final node = ctx.getValue('node') as Node;
    final inputs = ctx.getValue('inputs') as Map<String, Value>;
    final value = inputs[node.inputs[0].id]?.data;
    return NodeExecution(
      result: NodeSuccess({
        node.outputs[0].id: Value(
          data: value?.toString() ?? '',
          type: NodeDataType.string,
          meta: null,
        ),
      }),
    );
  }
}

class CommonNodePrototypes {
  static final constValue = NodePrototype(
    name: 'Const',
    description: 'Constant value',
    executor: const _ConstExecutor(),
    outputs: [
      SocketPrototype(
        name: 'value',
        description: 'Value',
        type: NodeDataType.any,
      ),
    ],
  );

  static final arithmeticInt = NodePrototype(
    name: 'Arithmetic',
    description: 'Integer arithmetic with operator input',
    executor: const _ArithmeticIntExecutor(),
    inputs: [
      SocketPrototype(name: 'a', description: 'Left', type: NodeDataType.int),
      SocketPrototype(name: 'b', description: 'Right', type: NodeDataType.int),
      SocketPrototype(
        name: 'op',
        description: 'Operator (+, -, *, /)',
        type: NodeDataType.string,
        defaultValue: Value(
          data: '+',
          type: NodeDataType.string,
          meta: null,
        ),
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


  static final boolOp = NodePrototype(
    name: 'BoolOp',
    description: 'Boolean/compare operation with condition input',
    executor: const _BoolOpExecutor(),
    inputs: [
      SocketPrototype(name: 'a', description: 'Left', type: NodeDataType.any),
      SocketPrototype(name: 'b', description: 'Right', type: NodeDataType.any),
      SocketPrototype(
        name: 'condition',
        description: '== != > >= < <= and or not',
        type: NodeDataType.string,
        defaultValue: Value(
          data: '==',
          type: NodeDataType.string,
          meta: null,
        ),
      ),
    ],
    outputs: [
      SocketPrototype(
        name: 'result',
        description: 'Result',
        type: NodeDataType.bool,
      ),
    ],
  );

  static final toStringNode = NodePrototype(
    name: 'ToString',
    description: 'Convert int to string',
    executor: const _ToStringExecutor(),
    inputs: [
      SocketPrototype(
        name: 'value',
        description: 'Value',
        type: NodeDataType.int,
      ),
    ],
    outputs: [
      SocketPrototype(
        name: 'result',
        description: 'Result',
        type: NodeDataType.string,
      ),
    ],
  );

  static List<NodePrototype> get list => [
    constValue,
    arithmeticInt,
    boolOp,
    toStringNode,
  ];
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
