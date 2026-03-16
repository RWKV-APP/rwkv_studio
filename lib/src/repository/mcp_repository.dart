import 'dart:async';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/settings/mcp_settings_model.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class McpServerStatus {
  final bool enabled;
  final bool checking;
  final bool connected;
  final String error;
  final int toolCount;
  final String serverName;
  final String serverVersion;
  final DateTime? checkedAt;

  const McpServerStatus({
    required this.enabled,
    required this.checking,
    required this.connected,
    required this.error,
    required this.toolCount,
    required this.serverName,
    required this.serverVersion,
    required this.checkedAt,
  });

  const McpServerStatus.disabled()
    : enabled = false,
      checking = false,
      connected = false,
      error = '',
      toolCount = 0,
      serverName = '',
      serverVersion = '',
      checkedAt = null;

  const McpServerStatus.checking()
    : enabled = true,
      checking = true,
      connected = false,
      error = '',
      toolCount = 0,
      serverName = '',
      serverVersion = '',
      checkedAt = null;

  factory McpServerStatus.connected({
    required int toolCount,
    required String serverName,
    required String serverVersion,
  }) {
    return McpServerStatus(
      enabled: true,
      checking: false,
      connected: true,
      error: '',
      toolCount: toolCount,
      serverName: serverName,
      serverVersion: serverVersion,
      checkedAt: DateTime.now(),
    );
  }

  factory McpServerStatus.unavailable(Object error) {
    return McpServerStatus(
      enabled: true,
      checking: false,
      connected: false,
      error: error.toString(),
      toolCount: 0,
      serverName: '',
      serverVersion: '',
      checkedAt: DateTime.now(),
    );
  }
}

class McpRepositorySnapshot {
  final Map<String, McpClient> clients;
  final Map<String, McpServerStatus> statuses;

  const McpRepositorySnapshot({
    this.clients = const {},
    this.statuses = const {},
  });
}

class McpRepository {
  final _snapshotController =
      StreamController<McpRepositorySnapshot>.broadcast();

  List<McpServerModel> _configs = const [];
  Map<String, McpClient> _clients = const {};
  Map<String, McpServerStatus> _statuses = const {};

  List<McpServerModel> get configs => _configs;

  Map<String, McpClient> get clients => _clients;

  Map<String, McpServerStatus> get statuses => _statuses;

  McpRepositorySnapshot get snapshot =>
      McpRepositorySnapshot(clients: _clients, statuses: _statuses);

  Stream<McpRepositorySnapshot> watchSnapshot() {
    return _snapshotController.stream;
  }

  Future<McpClient?> connectServer(McpServerModel config) async {
    if (!config.enabled) {
      return null;
    }

    if (config.isStdio) {
      if (config.command.trim().isEmpty) {
        return null;
      }
      return McpClient.stdio(
        id: config.id,
        command: config.command,
        args: config.args,
        workingDirectory: config.workingDirectory.trim().isEmpty
            ? null
            : config.workingDirectory,
        environment: config.environment.isEmpty ? null : config.environment,
        includeParentEnvironment: config.includeParentEnvironment,
        requestTimeout: Duration(milliseconds: config.requestTimeoutMs),
        onStderr: (line) {
          logw('[MCP/${config.id}] $line');
        },
      );
    }

    if (config.url.trim().isEmpty) {
      return null;
    }

    return McpClient.streamableHttp(
      id: config.id,
      endpoint: Uri.parse(config.url),
      headers: config.headers,
      requestTimeout: Duration(milliseconds: config.requestTimeoutMs),
      openEventStream: config.openEventStream,
      deleteSessionOnClose: config.deleteSessionOnClose,
    );
  }

  Future testConnection(McpServerModel config) async {
    final client = await connectServer(config);
    if (client == null) {
      return false;
    }

    if (_statuses[config.id]?.checking == true) {
      throw const AppException.unsupported(
        'Please wait for the previous connection check to complete',
      );
    }

    try {
      _statuses = {..._statuses, config.id: const McpServerStatus.checking()};
      _emitSnapshot();
      await client.connect();
      await client.listTools(refresh: true);
      return true;
    } finally {
      await client.close();
    }
  }

  Future<void> syncConnections(Iterable<McpServerModel> configs) async {
    _configs = configs.toList();
    _statuses = {
      for (final config in _configs)
        config.id: config.enabled
            ? const McpServerStatus.checking()
            : const McpServerStatus.disabled(),
    };
    _emitSnapshot();
    await _refreshRuntime();
  }

  Future<void> refreshConnections() async {
    await _refreshRuntime();
  }

  McpClient getClient(String id) {
    final client = _clients[id];
    if (client == null) {
      throw AppException.notFound('MCP client not found: $id');
    }
    return client;
  }

  List<McpClient> getClients([Iterable<String>? ids]) {
    if (ids == null) {
      return _clients.values.toList();
    }

    return ids.map(getClient).toList();
  }

  McpHub buildHub({Iterable<String>? serverIds, bool namespaceTools = false}) {
    final selected = getClients(serverIds);
    if (selected.isEmpty) {
      throw const AppException.configuration('No MCP server connected');
    }
    return McpHub(servers: selected, namespaceTools: namespaceTools);
  }

  Future<void> dispose() async {
    await _closeClients(_clients.values);
    _configs = const [];
    _clients = const {};
    _statuses = const {};
    await _snapshotController.close();
  }

  Future<void> _refreshRuntime() async {
    final nextStatuses = <String, McpServerStatus>{
      for (final config in _configs)
        config.id: config.enabled
            ? const McpServerStatus.checking()
            : const McpServerStatus.disabled(),
    };

    final previousClients = _clients.values.toList();
    _clients = const {};
    _statuses = nextStatuses;
    _emitSnapshot();

    await _closeClients(previousClients);

    final nextClients = <String, McpClient>{};
    for (final config in _configs.where((item) => item.enabled)) {
      McpClient? client;
      try {
        client = await connectServer(config);
        if (client == null) {
          nextStatuses[config.id] = McpServerStatus.unavailable(
            'invalid MCP server config',
          );
          _statuses = Map<String, McpServerStatus>.from(nextStatuses);
          _emitSnapshot();
          continue;
        }

        await client.connect();
        final tools = await client.listTools(refresh: true);
        nextClients[config.id] = client;
        nextStatuses[config.id] = McpServerStatus.connected(
          toolCount: tools.length,
          serverName: client.serverInfo?.name ?? '',
          serverVersion: client.serverInfo?.version ?? '',
        );
        logd(
          'connected MCP server ${config.id} tools=${tools.length} '
          'server=${client.serverInfo?.name ?? '-'}',
        );
      } catch (e, s) {
        final error = AppException.wrap(e, s);
        nextStatuses[config.id] = McpServerStatus.unavailable(
          error.displayMessage,
        );
        loge('McpRepository connect failed: ${config.id}', error, s);
        if (client != null) {
          await client.close();
        }
      }

      _clients = Map<String, McpClient>.from(nextClients);
      _statuses = Map<String, McpServerStatus>.from(nextStatuses);
      _emitSnapshot();
    }

    _clients = nextClients;
    _statuses = nextStatuses;
    _emitSnapshot();
  }

  Future<void> _closeClients(Iterable<McpClient> clients) async {
    for (final client in clients) {
      try {
        await client.close();
      } catch (e, s) {
        loge('McpRepository close client failed', e, s);
      }
    }
  }

  void _emitSnapshot() {
    if (_snapshotController.isClosed) {
      return;
    }
    _snapshotController.add(snapshot);
  }
}
