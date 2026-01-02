import 'dart:async';
import 'dart:collection';

import 'export.dart';

class Task {
  final NodeId nodeId;
  final Token token;
  final int attempt;

  Task({required this.nodeId, required this.token, required this.attempt});
}

class Semaphore {
  int _permits;
  final _waiters = <Completer<void>>[];

  Semaphore(this._permits);

  bool get hasPermit => _permits > 0;

  Future<void> acquire() {
    if (_permits > 0) {
      _permits--;
      return Future.value();
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _permits++;
    }
  }
}

class RunResult {
  final bool ok;
  final Object? error;

  const RunResult.ok() : ok = true, error = null;

  const RunResult.fail(this.error) : ok = false;

  const RunResult.cancelled() : ok = false, error = 'cancelled';
}

class Scheduler {
  static final CacheStore _globalCache = CacheStore();

  final int maxConcurrent;

  Scheduler({this.maxConcurrent = 4});

  int _tokenSeq = 0;

  String _nextTokenId() => 't${_tokenSeq++}';

  final Queue<Task> _ready = Queue<Task>();
  late final Semaphore _sem;
  int _running = 0;
  int _suspended = 0;

  Completer<RunResult>? _done;

  Future<RunResult> start({
    required RunPlan plan,
    required RunSession session,
  }) {
    _sem = Semaphore(maxConcurrent);
    _done = Completer<RunResult>();

    for (final entry in plan.entryNodes) {
      onControlToken(
        plan,
        session,
        Token(id: _nextTokenId(), from: '__entry__', to: entry),
    );
    }
    for (final entry in plan.nodes.entries) {
      final node = entry.value;
      if (node.inputs.isEmpty) continue;
      final hasControlIn = plan.inControl[node.id]?.isNotEmpty ?? false;
      if (hasControlIn) continue;
      final st = session.nodeStates[node.id]!;
      if (st.missingRequired.isEmpty && st.controlQueue.isEmpty) {
        st.controlQueue.add(
          Token(id: _nextTokenId(), from: '__auto__', to: node.id),
    );
      }
    }

    _pump(plan, session);
    return _done!.future;
  }

  void onControlToken(RunPlan plan, RunSession session, Token t) {
    if (session.cancel.isCancelled) return;
    final st = session.nodeStates[t.to]!;
    if (st.closed) return;
    st.controlQueue.add(t);
    _maybeEnqueue(plan, session, t.to);
  }

  void onDataValue(
    RunPlan plan,
    RunSession session,
    NodeId nodeId,
    String port,
    Value v,
  ) {
    if (session.cancel.isCancelled) return;
    final st = session.nodeStates[nodeId]!;
    if (st.closed) return;
    st.inputs[port] = v;
    st.missingRequired.remove(port);
    final hasControlIn = plan.inControl[nodeId]?.isNotEmpty ?? false;
    if (!hasControlIn &&
        st.controlQueue.isEmpty &&
        st.missingRequired.isEmpty &&
        !st.running) {
      st.controlQueue.add(
        Token(id: _nextTokenId(), from: '__data__', to: nodeId),
    );
    }
    _maybeEnqueue(plan, session, nodeId);
  }

  void _maybeEnqueue(RunPlan plan, RunSession session, NodeId nodeId) {
    final st = session.nodeStates[nodeId]!;
    if (st.closed || st.running) return;
    if (st.controlQueue.isEmpty) return;
    if (st.missingRequired.isNotEmpty) return;

    final token = st.controlQueue.removeFirst();
    _ready.add(Task(nodeId: nodeId, token: token, attempt: st.attempt));
    _pump(plan, session);
  }

  void _pump(RunPlan plan, RunSession session) {
    if (_done?.isCompleted == true) return;
    if (session.cancel.isCancelled) {
      _finish(const RunResult.cancelled());
      return;
    }

    while (_ready.isNotEmpty && _sem.hasPermit) {
      final task = _ready.removeFirst();
      _runTask(plan, session, task);
    }
    if (_ready.isEmpty && _running == 0 && _suspended == 0) {
      _finish(const RunResult.ok());
    }
  }

  void _finish(RunResult r) {
    if (_done != null && !(_done!.isCompleted)) {
      _done!.complete(r);
    }
  }

  Future<void> _runTask(RunPlan plan, RunSession session, Task task) async {
    await _sem.acquire();
    _running++;

    final st = session.nodeStates[task.nodeId]!;
    if (st.closed || session.cancel.isCancelled) {
      _running--;
      _sem.release();
      _pump(plan, session);
      return;
    }

    st.running = true;

    final node = plan.nodes[task.nodeId]!;
    final nodeRunId = session.nodeRunStore.start(
      session.runId,
      task.nodeId,
      attempt: task.attempt,
    );
    final startTime = DateTime.now();
    session.telemetry.emit(
      NodeStartEvent(
        runId: session.runId,
        nodeId: node.id,
        attempt: task.attempt,
        at: startTime,
      ),
    );
    try {
      final policy = node.prototype.policy;
      final inputSnapshot = Map<String, Value>.from(st.inputs);
      final cacheKey = _cacheKey(node, inputSnapshot, policy.cachePolicy);
      final cached = _getCache(
        session,
        policy.cachePolicy,
        policy.cacheTtl,
        cacheKey,
      );
      if (cached != null) {
        await _handleResult(
          plan,
          session,
          node,
          task,
          nodeRunId,
          null,
          startTime,
          NodeSuccess(cached.outputs),
        );
        return;
      }

      final exec = _invokeWithPolicy(session, node, task);
      if (exec.result != null) {
        await _handleResult(
          plan,
          session,
          node,
          task,
          nodeRunId,
          cacheKey,
          startTime,
          exec.result!,
        );
      } else if (exec.future != null) {
        final res = await exec.future!;
        await _handleResult(
          plan,
          session,
          node,
          task,
          nodeRunId,
          cacheKey,
          startTime,
          res,
        );
      } else if (exec.stream != null) {
        await _consumeStream(
          plan,
          session,
          node,
          task,
          nodeRunId,
          startTime,
          exec.stream!,
        );
      }
    } finally {
      st.running = false;
      _running--;
      _sem.release();

      _maybeEnqueue(plan, session, task.nodeId);
      _pump(plan, session);
    }
  }

  NodeExecution _invokeWithPolicy(RunSession session, Node node, Task task) {
    final proto = node.prototype;

    NodeContext createContext() {
      final ctx = NodeContext(
        idempotencyKey: proto.semantics == NodeSemantics.sideEffect
            ? '${session.runId}:${node.id}:${task.attempt}'
            : null,
      );
      ctx.setValue(
        'inputs',
        Map<String, Value>.from(session.nodeStates[node.id]!.inputs),
    );
      ctx.setValue('params', node.params);
      ctx.setValue('token', task.token);
      ctx.setValue('cancel', session.cancel);
      ctx.setValue('runId', session.runId);
      ctx.setValue('nodeId', node.id);
      return ctx;
    }

    Future<NodeResult> withTimeout(Future<NodeResult> f) async {
      if (proto.timeout <= Duration.zero) return f;
      return f.timeout(
        proto.timeout,
        onTimeout: () {
          return NodeFail(
            TimeoutException('Node ${node.id} timeout ${proto.timeout}'),
            retryable: true,
          );
        },
      );
    }

    Stream<NodeResult> withStreamTimeout(Stream<NodeResult> s) {
      if (proto.timeout <= Duration.zero) return s;
      return s.timeout(
        proto.timeout,
        onTimeout: (sink) {
          sink.add(
            NodeFail(
              TimeoutException('Node ${node.id} timeout ${proto.timeout}'),
              retryable: true,
            ),
    );
          sink.close();
        },
      );
    }

    final exec = proto.executor.execute(createContext());
    if (proto.dispatchType == NodeDispatchType.streaming &&
        exec.stream == null) {
      return NodeExecution(
        result: NodeFail(StateError('Streaming node must return a stream')),
    );
    }
    if (exec.result != null) {
      return NodeExecution(result: exec.result);
    }
    if (exec.future != null) {
      return NodeExecution(future: withTimeout(exec.future!));
    }
    if (exec.stream != null) {
      return NodeExecution(stream: withStreamTimeout(exec.stream!));
    }
    return NodeExecution(
      result: NodeFail(StateError('Node execution returned no result')),
    );
  }

  Future<bool> _handleResult(
    RunPlan plan,
    RunSession session,
    Node node,
    Task task,
    String nodeRunId,
    String? cacheKey,
    DateTime startTime,
    NodeResult res, {
    bool streaming = false,
    int? streamIndex,
  }) async {
    final st = session.nodeStates[node.id]!;
    if (session.cancel.isCancelled) {
      st.closed = true;
      session.telemetry.emit(
        NodeFailEvt(
          runId: session.runId,
          nodeId: node.id,
          error: 'cancelled',
          retryable: false,
        ),
    );
      _emitEnd(
        session,
        node,
        startTime,
        result: null,
        success: false,
        error: 'cancelled',
      );
      _finish(const RunResult.cancelled());
      return true;
    }

    switch (res) {
      case NodeSuccess s:
        session.telemetry.emit(
          NodeSuccessEvt(
            runId: session.runId,
            nodeId: node.id,
            streaming: streaming,
            streamIndex: streamIndex,
          ),
    );
        _propagateData(plan, session, node.id, s.outputs);
        _propagateControl(plan, session, node.id, s.control);
        if (!streaming) {
          if (cacheKey != null) {
            _storeCache(
              session,
              node.prototype.policy.cachePolicy,
              node.prototype.policy.cacheTtl,
              cacheKey,
              s.outputs,
            );
          }
          _emitEnd(
            session,
            node,
            startTime,
            result: s.outputs,
            success: true,
            error: null,
          );
          return true;
        }
        return false;

      case NodeSuspend su:
        st.running = false;
        _suspended++;
        session.telemetry.emit(
          NodeSuspendEvt(runId: session.runId, nodeId: node.id),
    );
        su.resume
            .then((finalRes) async {
          if (session.cancel.isCancelled) return;
          _suspended--;
          session.telemetry.emit(
            NodeResumeEvt(runId: session.runId, nodeId: node.id),
    );
          await _handleResult(
            plan,
            session,
            node,
            task,
            nodeRunId,
          cacheKey,
          startTime,
            finalRes,
          );

          _pump(plan, session);
        })
            .catchError((e, st) {
          _suspended--;
          session.telemetry.emit(
            NodeFailEvt(
              runId: session.runId,
              nodeId: node.id,
              error: e,
              retryable: false,
            ),
    );
          _emitEnd(
            session,
            node,
            startTime,
            result: null,
            success: false,
            error: e.toString(),
    );
          _finish(RunResult.fail(e));
        });

        return false;

      case NodeFail f:
        session.telemetry.emit(
          NodeFailEvt(
            runId: session.runId,
            nodeId: node.id,
            error: f.error,
            retryable: f.retryable,
          ),
    );

        final proto = node.prototype;
        final canRetry = f.retryable && task.attempt < proto.policy.maxRetries;

        if (canRetry) {
          final nextAttempt = task.attempt + 1;
          session.nodeStates[node.id]!.attempt = nextAttempt;

          final delay = proto.policy.delayFor(nextAttempt);
          Future.delayed(delay, () {
            if (session.cancel.isCancelled) return;
            _ready.add(
              Task(nodeId: node.id, token: task.token, attempt: nextAttempt),
    );
            _pump(plan, session);
          });
          return true;
        }

        st.closed = true;
        _emitEnd(
          session,
          node,
          startTime,
          result: null,
          success: false,
          error: f.error.toString(),
    );
        _finish(RunResult.fail(f.error));
        return true;
    }
  }

  Future<void> _consumeStream(
    RunPlan plan,
    RunSession session,
    Node node,
    Task task,
    String nodeRunId,
    DateTime startTime,
    Stream<NodeResult> stream,
  ) async {
    var index = 0;
    await for (final res in stream) {
      if (session.cancel.isCancelled) return;
      if (res is NodeSuspend) {
        await _handleResult(
          plan,
          session,
          node,
          task,
          nodeRunId,
          null,
          startTime,
          NodeFail(
            StateError('Suspend not supported for streaming nodes'),
            retryable: false,
          ),
        );
        return;
      }
      final done = await _handleResult(
        plan,
        session,
        node,
        task,
        nodeRunId,
        null,
        startTime,
        res,
        streaming: res is NodeSuccess,
        streamIndex: res is NodeSuccess ? index : null,
      );
      if (res is NodeSuccess) {
        index++;
      }
      if (done) {
        return;
      }
    }
    _emitEnd(
      session,
      node,
      startTime,
      result: null,
      success: true,
      error: null,
    );
  }

  void _emitEnd(
    RunSession session,
    Node node,
    DateTime startTime, {
    required dynamic result,
    required bool success,
    required String? error,
  }) {
    session.telemetry.emit(
      NodeEndEvent(
        runId: session.runId,
        nodeId: node.id,
        duration: DateTime.now().difference(startTime),
        result: result,
        success: success,
        error: error,
      ),
    );
  }

  CacheStore _storeFor(RunSession session, NodeCacheLevel level) {
    return level == NodeCacheLevel.forever ? _globalCache : session.cacheStore;
  }

  String _cacheKey(
    Node node,
    Map<String, Value> inputs,
    NodeCacheLevel level,
  ) {
    final base = level == NodeCacheLevel.forever ? node.prototype.name : node.id;
    final params = _stableParams(node.params);
    final inputSig = _stableInputs(inputs);
    return '$base|$params|$inputSig';
  }

  Cache? _getCache(
    RunSession session,
    NodeCacheLevel level,
    Duration ttl,
    String key,
  ) {
    if (level == NodeCacheLevel.none) return null;
    if (level == NodeCacheLevel.duration && ttl <= Duration.zero) return null;
    final store = _storeFor(session, level);
    final cache = store.get(key);
    if (cache == null) return null;
    if (!_isCacheValid(cache, level, ttl)) {
      store.remove(key);
      return null;
    }
    return cache;
  }

  void _storeCache(
    RunSession session,
    NodeCacheLevel level,
    Duration ttl,
    String key,
    Map<String, Value> outputs,
  ) {
    if (level == NodeCacheLevel.none) return;
    if (level == NodeCacheLevel.duration && ttl <= Duration.zero) return;
    final now = DateTime.now();
    final store = _storeFor(session, level);
    final existing = store.get(key);
    store.put(
      key,
      Cache(
        hash: key,
        outputs: Map<String, Value>.from(outputs),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        ttl: ttl,
        crossRun: level == NodeCacheLevel.forever,
      ),
    );
  }

  bool _isCacheValid(Cache cache, NodeCacheLevel level, Duration ttl) {
    if (level == NodeCacheLevel.duration || ttl > Duration.zero) {
      if (ttl <= Duration.zero) return false;
      return DateTime.now().difference(cache.updatedAt) <= ttl;
    }
    return true;
  }

  String _stableParams(Map<String, dynamic> params) {
    final keys = params.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      final value = params[key];
      buffer.write('$key=${value?.toString() ?? ''};');
    }
    return buffer.toString();
  }

  String _stableInputs(Map<String, Value> inputs) {
    final keys = inputs.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final key in keys) {
      final value = inputs[key];
      buffer.write('$key=${value == null ? '' : _valueDigest(value)};');
    }
    return buffer.toString();
  }

  String _valueDigest(Value value) {
    final meta = value.meta;
    return '${value.type.id}:${value.data}:${meta ?? ''}';
  }
  void _propagateData(
    RunPlan plan,
    RunSession session,
    NodeId fromNodeId,
    Map<String, Value> outputs,
  ) {
    final outEdges = plan.outData[fromNodeId] ?? const <NodeEdge>[];
    if (outEdges.isEmpty) return;

    for (final e in outEdges) {
      final v = outputs[e.fromSocket];
      if (v == null) continue;
      onDataValue(plan, session, e.toNodeId, e.toSocket, v);
    }
  }

  void _propagateControl(
    RunPlan plan,
    RunSession session,
    NodeId fromNodeId,
    List<ControlEmission> emissions,
  ) {
    final outEdges = plan.outControl[fromNodeId] ?? const <NodeEdge>[];
    if (outEdges.isEmpty) return;

    for (final em in emissions) {
      for (final e in outEdges) {
        if (e.fromSocket != em.port) continue;
        onControlToken(
          plan,
          session,
          Token(
            id: _nextTokenId(),
            from: fromNodeId,
            to: e.toNodeId,
            payload: em.payload,
          ),
    );
      }
    }
  }
}

class RunTelemetry {
  final StreamController<TelemetryEvent> _controller =
      StreamController<TelemetryEvent>();

  RunTelemetry();

  void emit(TelemetryEvent event) {
    _controller.add(event);
  }

  Stream<TelemetryEvent> get stream => _controller.stream;

  Future<void> close() => _controller.close();
}

sealed class TelemetryEvent {}

class NodeStartEvent extends TelemetryEvent {
  final String runId;
  final String nodeId;
  final int attempt;
  final DateTime at;

  NodeStartEvent({
    required this.runId,
    required this.nodeId,
    required this.attempt,
    required this.at,
  });
}

class NodeSuccessEvt extends TelemetryEvent {
  final String runId;
  final String nodeId;
  final bool streaming;
  final int? streamIndex;

  NodeSuccessEvt({
    required this.runId,
    required this.nodeId,
    required this.streaming,
    this.streamIndex,
  });
}

class NodeSuspendEvt extends TelemetryEvent {
  final String runId;
  final String nodeId;

  NodeSuspendEvt({required this.runId, required this.nodeId});
}

class NodeResumeEvt extends TelemetryEvent {
  final String runId;
  final String nodeId;

  NodeResumeEvt({required this.runId, required this.nodeId});
}

class NodeFailEvt extends TelemetryEvent {
  final String runId;
  final String nodeId;
  final Object error;
  final bool retryable;

  NodeFailEvt({
    required this.runId,
    required this.nodeId,
    required this.error,
    required this.retryable,
  });
}

class NodeEndEvent extends TelemetryEvent {
  final String runId;
  final String nodeId;
  final Duration duration;
  final dynamic result;
  final bool success;
  final String? error;

  NodeEndEvent({
    required this.runId,
    required this.nodeId,
    required this.duration,
    required this.result,
    required this.success,
    required this.error,
  });
}
