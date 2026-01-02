import 'dart:async';
import 'dart:collection';

import 'export.dart';

class CancelToken {
  final void Function()? _onCancel;
  bool _isCancelled = false;

  CancelToken({void Function()? onCancel}) : _onCancel = onCancel;

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _onCancel?.call();
  }
}

class RunHandle {
  final RunSession session;
  final CancelToken cancelToken;
  final Future<RunResult> done;

  final RunTelemetry telemetry;

  RunHandle({
    required this.session,
    required this.cancelToken,
    required this.done,
    required this.telemetry,
  });

  StreamSubscription<TelemetryEvent> subscribe(
    void Function(TelemetryEvent event) onEvent,
  ) {
    return telemetry.stream.listen(onEvent);
  }

  void cancel() {
    cancelToken.cancel();
  }
}

class NodeEngine {
  final Compiler compiler;
  final Scheduler scheduler;
  final Registry registry;

  NodeEngine({
    required this.compiler,
    required this.scheduler,
    required this.registry,
  });

  factory NodeEngine.def() {
    return NodeEngine(
      compiler: Compiler(),
      scheduler: Scheduler(),
      registry: Registry(),
    );
  }

  RunHandle run(NodeGroup group, {Map<SocketId, Value> inputs = const {}}) {
    final plan = compiler.compile(group);

    final telemetry = RunTelemetry();

    final session = RunSession.create(
      plan: plan,
      initialInputs: inputs,
      telemetry: telemetry,
    );

    final done = scheduler.start(plan: plan, session: session);

    return RunHandle(
      session: session,
      cancelToken: session.cancel,
      done: done,
      telemetry: telemetry,
    );
  }
}

class Token {
  final String id;
  final NodeId from;
  final NodeId to;
  final Value? payload;

  Token({required this.id, required this.from, required this.to, this.payload});
}

class Snapshot {
  final NodeContext context;
  final List<Value> inputs;
  final List<Value> outputs;

  Snapshot({
    required this.inputs,
    required this.outputs,
    required this.context,
  });
}

enum RunStatus {
  //
  ready,
  running,
  suspended,
  success,
  failed,
  canceled,
}

typedef NodeRunId = String;

class RuntimeNodeState {
  final Queue<Token> controlQueue = Queue<Token>();
  final Map<String, Value> inputs = {};
  final Set<String> missingRequired;

  bool running = false;
  bool closed = false;
  int attempt = 0;

  RuntimeNodeState({required Set<String> required})
    : missingRequired = Set<String>.from(required);

  static Map<NodeId, RuntimeNodeState> create(RunPlan plan) {
    final m = <NodeId, RuntimeNodeState>{};

    plan.nodes.forEach((id, node) {
      final requiredInputs = node.inputs
          .where((p) => p.prototype.required)
          .map((p) => p.id)
          .toSet();
      final s = RuntimeNodeState(required: requiredInputs);
      for (final p in node.inputs) {
        final hasIncoming = (plan.inDataByPort[id]?.containsKey(p.id) ?? false);
        final defaultValue = p.prototype.defaultValue;
        if (!hasIncoming && defaultValue != null) {
          s.inputs[p.id] = defaultValue;
          s.missingRequired.remove(p.id);
        }
      }
      m[id] = s;
    });
    return m;
  }
}

class ResumeHandle {
  final NodeRunId runId;
  final Function() callback;
  final dynamic token;

  ResumeHandle({required this.runId, required this.callback, this.token});
}

class NodeRunStore {
  int _seq = 0;

  NodeRunId start(String runId, NodeId nodeId, {required int attempt}) {
    final id = '${runId}_${nodeId}_${attempt}_${_seq++}';
    return id;
  }
}

class CacheStore {
  final Map<String, Cache> _entries = {};

  Cache? get(String key) => _entries[key];

  void put(String key, Cache value) {
    _entries[key] = value;
  }

  void remove(String key) {
    _entries.remove(key);
  }
}

typedef SessionId = String;

class RunSession {
  final String runId;
  final CancelToken cancel;
  final RunTelemetry telemetry;
  final NodeRunStore nodeRunStore;
  final Map<NodeId, RuntimeNodeState> nodeStates;
  final CacheStore cacheStore;

  RunSession({
    required this.runId,
    required this.cancel,
    required this.telemetry,
    required this.nodeRunStore,
    required this.nodeStates,
    required this.cacheStore,
  });

  static RunSession create({
    required RunPlan plan,
    required Map<SocketId, Value> initialInputs,
    required RunTelemetry telemetry,
  }) {
    final runId = DateTime.now().millisecondsSinceEpoch.toString();
    final cancel = CancelToken();
    final nodeRunStore = NodeRunStore();
    final nodeStates = RuntimeNodeState.create(plan);
    final cacheStore = CacheStore();
    for (final entry in initialInputs.entries) {
      final socketId = entry.key;
      for (final node in plan.nodes.values) {
        final match = node.inputs.where((i) => i.id == socketId);
        if (match.isEmpty) continue;
        final st = nodeStates[node.id]!;
        st.inputs[socketId] = entry.value;
        st.missingRequired.remove(socketId);
        break;
      }
    }
    return RunSession(
      runId: runId,
      cancel: cancel,
      telemetry: telemetry,
      nodeRunStore: nodeRunStore,
      nodeStates: nodeStates,
      cacheStore: cacheStore,
    );
  }

  void cancelRun() => cancel.cancel();
}
