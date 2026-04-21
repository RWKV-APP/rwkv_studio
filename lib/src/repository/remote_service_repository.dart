import 'dart:async';
import 'dart:convert';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/model/model_service_wrap.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/models/settings/model_settings_model.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class RemoteServiceStatus {
  final bool enabled;
  final bool checking;
  final bool available;
  final String error;
  final int modelCount;
  final DateTime? checkedAt;

  const RemoteServiceStatus({
    required this.enabled,
    required this.checking,
    required this.available,
    required this.error,
    required this.modelCount,
    required this.checkedAt,
  });

  const RemoteServiceStatus.disabled()
    : enabled = false,
      checking = false,
      available = false,
      error = '',
      modelCount = 0,
      checkedAt = null;

  const RemoteServiceStatus.checking()
    : enabled = true,
      checking = true,
      available = false,
      error = '',
      modelCount = 0,
      checkedAt = null;

  factory RemoteServiceStatus.available(int modelCount) {
    return RemoteServiceStatus(
      enabled: true,
      checking: false,
      available: true,
      error: '',
      modelCount: modelCount,
      checkedAt: DateTime.now(),
    );
  }

  factory RemoteServiceStatus.unavailable(Object error) {
    return RemoteServiceStatus(
      enabled: true,
      checking: false,
      available: false,
      error: error.toString(),
      modelCount: 0,
      checkedAt: DateTime.now(),
    );
  }
}

class RemoteServiceSnapshot {
  final List<ModelServiceWrap> services;
  final List<RemoteModelInfo> remoteModels;
  final Map<String, RemoteServiceStatus> statuses;

  const RemoteServiceSnapshot({
    this.services = const [],
    this.remoteModels = const [],
    this.statuses = const {},
  });
}

class RemoteServiceConnection {
  final RemoteServiceModel config;
  final ModelService service;

  const RemoteServiceConnection({required this.config, required this.service});
}

class RemoteServiceRepository {
  static const Duration _snapshotEmitDelay = Duration(milliseconds: 200);

  final StreamController<RemoteServiceSnapshot> _snapshotController =
      StreamController<RemoteServiceSnapshot>.broadcast();
  List<RemoteServiceModel> _configs = const [];
  List<ModelServiceWrap> _services = const [];
  List<RemoteModelInfo> _cachedRemoteModels = const [];
  Map<String, RemoteServiceStatus> _statuses = const {};
  Timer? _snapshotEmitTimer;
  String? _lastEmittedSnapshotFingerprint;

  RemoteServiceRepository() {
    _lastEmittedSnapshotFingerprint = _snapshotFingerprint();
  }

  List<ModelServiceWrap> get connectedServices => _services;

  List<RemoteModelInfo> get cachedRemoteModels => _cachedRemoteModels;

  Map<String, RemoteServiceStatus> get statuses => _statuses;

  RemoteServiceSnapshot get snapshot => RemoteServiceSnapshot(
    services: _services,
    remoteModels: _cachedRemoteModels,
    statuses: _statuses,
  );

  Stream<RemoteServiceSnapshot> watchSnapshot() {
    return _snapshotController.stream;
  }

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

  Future<void> syncConnections(Iterable<RemoteServiceModel> configs) async {
    _configs = configs.toList(growable: false);
    await _refreshRuntime();
  }

  Future<bool> testConnection(RemoteServiceModel config) async {
    final connection = await connectService(config);
    return connection?.service.available ?? false;
  }

  Future<void> refreshConnections() async {
    await _refreshRuntime();
  }

  Future<List<RemoteModelInfo>> fetchRemoteModels({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedRemoteModels.isNotEmpty) {
      return _cachedRemoteModels;
    }
    await _refreshRuntime();
    return _cachedRemoteModels;
  }

  Future<void> dispose() async {
    _snapshotEmitTimer?.cancel();
    _snapshotEmitTimer = null;
    _configs = const [];
    _services = const [];
    _cachedRemoteModels = const [];
    _statuses = const {};
    await _snapshotController.close();
  }

  Future<void> _refreshRuntime() async {
    final services = <ModelServiceWrap>[];
    final models = <RemoteModelInfo>[];
    final statuses = <String, RemoteServiceStatus>{
      for (final config in _configs)
        config.id: config.enabled && config.url.trim().isNotEmpty
            ? const RemoteServiceStatus.checking()
            : const RemoteServiceStatus.disabled(),
    };
    _statuses = statuses;
    _services = _services
        .where((service) => _activeConfigMatches(service.id, service.url))
        .toList(growable: false);
    _cachedRemoteModels = _cachedRemoteModels
        .where(
          (model) => _activeConfigMatches(model.serviceId, model.providerUrl),
        )
        .toList(growable: false);
    _emitSnapshot();

    for (final config in _configs.where(
      (config) => config.enabled && config.url.trim().isNotEmpty,
    )) {
      try {
        final connection = await connectService(config);
        if (connection == null || !connection.service.available) {
          statuses[config.id] = RemoteServiceStatus.unavailable(
            'service unavailable',
          );
          continue;
        }

        final service = ModelServiceWrap(
          connection.service,
          name: connection.config.name,
        );
        final remoteModels = service.models
            .map(
              (model) => RemoteModelInfo.fromMap(model.info.toJson())
                ..serviceId = service.id
                ..providerName = service.sourceName
                ..providerUrl = service.url,
            )
            .toList();
        services.add(service);
        models.addAll(remoteModels);
        statuses[config.id] = RemoteServiceStatus.available(
          remoteModels.length,
        );
        logd(
          'synced ${remoteModels.length} models from ${service.id} (${service.url})',
        );
      } on TimeoutException catch (e, s) {
        final error = AppException.timeout(
          'Timeout fetching models from ${config.id} (${config.url})',
          stackTrace: s,
          cause: e,
        );
        statuses[config.id] = RemoteServiceStatus.unavailable(
          error.displayMessage,
        );
        loge(error, null, error.stackTrace ?? s);
      } catch (e, s) {
        final error = AppException.wrap(e, s);
        statuses[config.id] = RemoteServiceStatus.unavailable(
          error.displayMessage,
        );
        loge(error, null, error.stackTrace ?? s);
      }
    }

    _services = services;
    _cachedRemoteModels = models;
    _statuses = statuses;
    _emitSnapshot(immediate: true);
  }

  bool _activeConfigMatches(String serviceId, String serviceUrl) {
    return _configs.any(
      (config) =>
          config.id == serviceId &&
          config.enabled &&
          config.url.trim().isNotEmpty &&
          config.url == serviceUrl,
    );
  }

  void _emitSnapshot({bool immediate = false}) {
    if (_snapshotController.isClosed) {
      return;
    }
    final fingerprint = _snapshotFingerprint();
    if (fingerprint == _lastEmittedSnapshotFingerprint) {
      _snapshotEmitTimer?.cancel();
      _snapshotEmitTimer = null;
      return;
    }

    if (immediate) {
      _snapshotEmitTimer?.cancel();
      _snapshotEmitTimer = null;
      _emitSnapshotNow(fingerprint);
      return;
    }

    _snapshotEmitTimer ??= Timer(_snapshotEmitDelay, () {
      _snapshotEmitTimer = null;
      if (_snapshotController.isClosed) {
        return;
      }
      final latestFingerprint = _snapshotFingerprint();
      if (latestFingerprint == _lastEmittedSnapshotFingerprint) {
        return;
      }
      _emitSnapshotNow(latestFingerprint);
    });
  }

  void _emitSnapshotNow(String fingerprint) {
    _lastEmittedSnapshotFingerprint = fingerprint;
    _snapshotController.add(snapshot);
  }

  String _snapshotFingerprint() {
    return jsonEncode({
      // Configs are not exposed in the snapshot, but they can change the
      // underlying service clients even when the visible model list is same.
      'configs': _configs
          .map(
            (config) => [
              config.id,
              config.name,
              config.url,
              config.enabled,
              config.apiKey,
            ],
          )
          .toList(growable: false),
      'services': _services
          .map(
            (service) => [
              service.id,
              service.sourceName,
              service.url,
              service.available,
              service.models.length,
            ],
          )
          .toList(growable: false),
      'models': _cachedRemoteModels
          .map(_remoteModelFingerprint)
          .toList(growable: false),
      'statuses': {
        for (final key in _statuses.keys.toList()..sort())
          key: _statusFingerprint(_statuses[key]!),
      },
    });
  }

  List<Object?> _statusFingerprint(RemoteServiceStatus status) {
    return [
      status.enabled,
      status.checking,
      status.available,
      status.error,
      status.modelCount,
    ];
  }

  List<Object?> _remoteModelFingerprint(RemoteModelInfo model) {
    return [
      model.serviceId,
      model.providerName,
      model.providerUrl,
      model.id,
      model.name,
      model.modelSize,
    ];
  }
}
