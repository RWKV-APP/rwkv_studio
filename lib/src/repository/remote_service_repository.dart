import 'dart:async';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/models/model/model_service_wrap.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/models/settings/model_settings_model.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class RemoteServiceConnection {
  final RemoteServiceModel config;
  final ModelService service;

  const RemoteServiceConnection({required this.config, required this.service});
}

class RemoteServiceRepository {
  List<RemoteServiceConnection> _connections = const [];
  List<ModelServiceWrap> _services = const [];
  List<RemoteModelInfo> _cachedRemoteModels = const [];

  List<ModelServiceWrap> get connectedServices => _services;

  List<RemoteModelInfo> get cachedRemoteModels => _cachedRemoteModels;

  Future<RemoteServiceConnection?> connectService(
    RemoteServiceModel config,
  ) async {
    if (config.url.trim().isEmpty) {
      return null;
    }
    final service = await ModelService.create(
      url: config.url,
      accessKey: config.apiKey,
      id: config.id,
    );
    return RemoteServiceConnection(config: config, service: service);
  }

  Future<List<RemoteServiceConnection>> connectServices(
    Iterable<RemoteServiceModel> configs,
  ) async {
    final connections = <RemoteServiceConnection>[];
    for (final config in configs) {
      final connection = await connectService(config);
      if (connection != null) {
        connections.add(connection);
      }
    }
    return connections;
  }

  Future<void> syncConnections(Iterable<RemoteServiceModel> configs) async {
    final connections = await connectServices(configs);
    _connections = connections;
    _services = [
      for (final connection in connections)
        ModelServiceWrap(connection.service, name: connection.config.name),
    ];
    _cachedRemoteModels = const [];
  }

  Future<bool> testConnection(RemoteServiceModel config) async {
    final connection = await connectService(config);
    return connection?.service.available ?? false;
  }

  Future<void> refreshConnections([
    Iterable<RemoteServiceConnection>? connections,
  ]) async {
    for (final connection in connections ?? _connections) {
      try {
        await connection.service.refresh();
      } catch (e, s) {
        loge(e, s);
      }
    }
  }

  Future<List<LoadedModel>> getLoadedModels([
    Iterable<RemoteServiceConnection>? connections,
  ]) async {
    final items = connections ?? _connections;
    return [for (final connection in items) ...connection.service.models];
  }

  Future<List<RemoteModelInfo>> fetchRemoteModels({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedRemoteModels.isNotEmpty) {
      return _cachedRemoteModels;
    }

    final models = <RemoteModelInfo>[];
    for (final service in _services) {
      try {
        await service.refresh();
        final remoteModels = service.models
            .map(
              (model) => RemoteModelInfo.fromMap(model.info.toJson())
                ..serviceId = service.id
                ..providerName = service.sourceName
                ..providerUrl = service.url,
            )
            .toList();
        logd(
          'synced ${remoteModels.length} models from ${service.id} (${service.url})',
        );
        models.addAll(remoteModels);
      } on TimeoutException {
        logw('timeout fetching models from ${service.id} (${service.url})');
      } catch (e, s) {
        loge(e, s);
      }
    }
    if (models.isNotEmpty || _services.isEmpty) {
      _cachedRemoteModels = models;
    }
    return _cachedRemoteModels;
  }

  Future<void> dispose() async {
    _connections = const [];
    _services = const [];
    _cachedRemoteModels = const [];
  }
}
