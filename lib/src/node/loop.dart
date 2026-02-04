import 'export.dart';

class LoopExecutor extends NodeExecutor {
  const LoopExecutor();

  @override
  NodeExecution execute(NodeContext ctx) {
    return NodeExecution(future: _runLoop(ctx));
  }

  Future<NodeResult> _runLoop(NodeContext ctx) async {
    final inputs = ctx.getValue('inputs') as Map<String, Value>;
    final params = ctx.getValue('params') as Map<String, dynamic>;
    final cancel = ctx.getValue('cancel') as CancelToken?;

    final countId = params['countId'] as String?;
    final valueId = params['valueId'] as String?;
    final outId = params['outId'] as String?;
    final body = params['body'] as NodeGroup?;
    final bodyValueInputId = params['bodyValueInputId'] as String?;
    final bodyIndexInputId = params['bodyIndexInputId'] as String?;
    final bodyResultNodeId = params['bodyResultNodeId'] as String?;
    final bodyResultInputId = params['bodyResultInputId'] as String?;

    if (countId == null ||
        valueId == null ||
        outId == null ||
        body == null ||
        bodyValueInputId == null ||
        bodyResultNodeId == null ||
        bodyResultInputId == null) {
      return NodeFail(StateError('Loop node params incomplete'));
    }

    final countValue = inputs[countId]?.data as int?;
    final startValue = inputs[valueId]?.data as int?;
    if (countValue == null || startValue == null) {
      return NodeFail(
        StateError('Loop node missing inputs: count=$countValue value=$startValue'),
      );
    }

    var current = startValue;
    if (countValue <= 0) {
      return NodeSuccess({
        outId: Value(data: current, type: NodeDataType.int, meta: null),
      });
    }

    for (var i = 0; i < countValue; i++) {
      if (cancel?.isCancelled == true) {
        return NodeFail(StateError('Loop cancelled'));
      }

      final engine = NodeEngine.def();
      final initialInputs = <SocketId, Value>{
        bodyValueInputId: Value(
          data: current,
          type: NodeDataType.int,
          meta: null,
        ),
      };
      if (bodyIndexInputId != null) {
        initialInputs[bodyIndexInputId] = Value(
          data: i,
          type: NodeDataType.int,
          meta: null,
        );
      }

      final handle = engine.run(body, inputs: initialInputs);
      final result = await handle.done;
      if (!result.ok) {
        return NodeFail(result.error ?? StateError('Loop body failed'));
      }

      final resultState = handle.session.nodeStates[bodyResultNodeId];
      final nextValue = resultState?.inputs[bodyResultInputId]?.data as int?;
      if (nextValue == null) {
        return NodeFail(
          StateError('Loop body produced no result for $bodyResultInputId'),
        );
      }
      current = nextValue;
    }

    return NodeSuccess({
      outId: Value(data: current, type: NodeDataType.int, meta: null),
    });
  }
}
