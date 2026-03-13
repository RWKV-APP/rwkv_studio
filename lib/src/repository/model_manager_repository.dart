import 'dart:async';

import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/cache/model_file_box.dart';

class ModelCatalogSnapshot {
  final List<ModelInfo> localModels;
  final List<ModelTag> tags;
  final List<ModelGroup> groups;
  final Map<String, TaskUpdate> taskUpdates;

  const ModelCatalogSnapshot({
    this.localModels = const [],
    this.tags = const [],
    this.groups = const [],
    this.taskUpdates = const {},
  });

  factory ModelCatalogSnapshot.empty() {
    return const ModelCatalogSnapshot();
  }
}

class ModelTaskUpdateEvent {
  final String modelId;
  final TaskUpdate update;
  final Object? error;

  const ModelTaskUpdateEvent({
    required this.modelId,
    required this.update,
    this.error,
  });
}

class ModelManagerRepository {
  ModelManager? _manager;
  StreamSubscription<DownloadEvent>? _taskUpdateSubscription;
  final StreamController<ModelTaskUpdateEvent> _taskUpdates =
      StreamController<ModelTaskUpdateEvent>.broadcast();

  bool get isInitialized => _manager != null;

  Future<void> ensureInitialized({
    required String modelDownloadDir,
    required String configProviderUrl,
    DownloadSource? downloadSource,
  }) async {
    if (_manager != null) {
      return;
    }
    final manager = ModelManager(
      downloadSource: downloadSource ?? DownloadSource.aiFastHub,
      configProviderUrl: configProviderUrl,
      modelDownloadDir: modelDownloadDir,
    );
    _manager = manager;
    _taskUpdateSubscription = manager.downloadUpdateEvents().listen((event) {
      _taskUpdates.add(
        ModelTaskUpdateEvent(
          modelId: event.model.id,
          update: event.update,
          error: event.error,
        ),
      );
    }, onError: _taskUpdates.addError);
    await manager.init();
  }

  Future<void> updateRuntimeConfig({
    String? modelDownloadDir,
    bool migration = false,
    String? configProviderUrl,
    DownloadSource? downloadSource,
  }) async {
    final manager = _requireManager();
    if (modelDownloadDir != null) {
      await manager.setModelDownloadDir(modelDownloadDir, migration: migration);
    }
    if (configProviderUrl != null) {
      manager.setConfigProviderUrl(configProviderUrl);
    }
    if (downloadSource != null) {
      manager.downloadSource = downloadSource;
    }
  }

  Stream<ModelTaskUpdateEvent> watchTaskUpdates() {
    return _taskUpdates.stream;
  }

  Future<ModelCatalogSnapshot> refreshLocalCatalog() async {
    final manager = _requireManager();
    await manager.updateConfig();
    return getCurrentCatalog();
  }

  Future<void> setModelDownloadDir(
    String path, {
    bool migration = false,
  }) async {
    await updateRuntimeConfig(modelDownloadDir: path, migration: migration);
  }

  Future<void> setConfigProviderUrl(String url) async {
    await updateRuntimeConfig(configProviderUrl: url);
  }

  Future<void> setDownloadSource(DownloadSource source) async {
    await updateRuntimeConfig(downloadSource: source);
  }

  Future<void> download(String id) async {
    await _requireManager().download(id);
  }

  Future<void> pause(String id) async {
    await _requireManager().pauseTask(id);
  }

  Future<void> resume(String id) async {
    await download(id);
  }

  Future<void> cancel(String id) async {
    await _requireManager().cancelTask(id);
  }

  Future<void> deleteLocalModelFiles(String id) async {
    await _requireManager().deleteLocalModelFiles(id);
  }

  Future<List<ModelInfo>> loadImportedModels() async {
    return ModelFileBox.getAllModels();
  }

  Future<List<ModelInfo>> saveImportedModel(ModelInfo model) async {
    await ModelFileBox.put(model);
    return ModelFileBox.getAllModels();
  }

  Future<List<ModelInfo>> deleteImportedModel(String id) async {
    await ModelFileBox.delete(id);
    return ModelFileBox.getAllModels();
  }

  ModelCatalogSnapshot getCurrentCatalog() {
    final manager = _manager;
    if (manager == null) {
      return ModelCatalogSnapshot.empty();
    }
    return ModelCatalogSnapshot(
      localModels: manager.models.where((e) {
        if (e.groups.contains('othello') || e.groups.contains('sudoku')) {
          return false;
        }
        return true;
      }).toList(),
      tags: manager.modelConfig.tags,
      groups: manager.modelConfig.groups,
      taskUpdates: {
        for (final entry in manager.downloadTasks.entries)
          entry.key: entry.value.update,
      },
    );
  }

  Future<void> dispose() async {
    await _taskUpdateSubscription?.cancel();
    await _taskUpdates.close();
  }

  ModelManager _requireManager() {
    final manager = _manager;
    if (manager == null) {
      throw StateError('ModelManagerRepository is not initialized');
    }
    return manager;
  }
}
