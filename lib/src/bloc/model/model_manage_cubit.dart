import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/repository/model_manager_repository.dart';
import 'package:rwkv_studio/src/repository/remote_service_repository.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'model_manage_state.dart';

extension Ext on BuildContext {
  ModelManageCubit get modelManage => read<ModelManageCubit>();
}

extension Ext2 on ModelManager {
  List<ModelInfo> get enabledModels => models.where((e) {
    if (e.groups.contains('othello') || e.groups.contains('sudoku')) {
      return false;
    }
    return true;
  }).toList();
}

class ModelManageCubit extends Cubit<ModelManageState> {
  final ModelManagerRepository _repository;
  final RemoteServiceRepository _remoteServiceRepository;
  StreamSubscription<ModelTaskUpdateEvent>? _taskUpdateSubscription;
  bool _managerInitialized = false;

  ModelManageCubit(this._repository, this._remoteServiceRepository)
    : super(ModelManageState.initial());

  Iterable<ModelInfo> get availableTextModels => [
    ...state.remoteModels,
    ...state.models.where(
      (e) =>
          (e.localPath.isNotEmpty) &&
          (e.groups.overlaps({'chat', 'albatross', 'roleplay'})),
    ),
  ];

  Future initManager({
    required String modelDownloadDir,
    required String configProviderUrl,
  }) async {
    if (kIsWeb || _managerInitialized) {
      return;
    }
    await _repository.initialize(
      modelDownloadDir: modelDownloadDir,
      configProviderUrl: configProviderUrl,
      downloadSource: state.downloadSource,
    );
    await _taskUpdateSubscription?.cancel();
    _taskUpdateSubscription = _repository.watchTaskUpdates().listen(
      (event) {
        _emitTaskUpdate(
          modelId: event.modelId,
          update: event.update,
          error: event.error,
        );
      },
      onError: (e) {
        loge(e);
      },
    );
    _emitCatalogSnapshot(
      _repository.getCurrentCatalog(),
      downloadDir: modelDownloadDir,
    );
    _managerInitialized = true;
  }

  Future setModelDownloadDir(String path, {bool migration = false}) async {
    if (!_managerInitialized) {
      return;
    }
    await _repository.setModelDownloadDir(path, migration: migration);
    logd('Model download dir set to $path, updating model list');
    await updateModelList(remote: false);
  }

  Future updateModelConfigUrl(String url) async {
    if (kIsWeb || !_managerInitialized) {
      return;
    }
    await _repository.setConfigProviderUrl(url);
    await updateModelList(remote: false);
  }

  Future init() async {
    if (state.initialized) {
      logw('ModelManageCubit already initialized');
      return;
    }
    if (kIsWeb) {
      return;
    }

    var importedModels = <ModelInfo>[];
    try {
      importedModels = await _repository.loadImportedModels();
    } catch (e) {
      logw(e);
    }
    emit(
      state.copyWith(
        initialized: true,
        importedModels: importedModels,
        backends: [
          ModelBackend.albatross,
          ModelBackend.llama_cpp,
          ModelBackend.web_rwkv,
          ModelBackend.pytorch,
        ],
      ),
    );
  }

  Future download(String id) async {
    try {
      await _repository.download(id);
    } catch (e) {
      _emitTaskUpdate(
        modelId: id,
        update: TaskUpdate.initial().copyWith(state: TaskState.stopped),
        error: e,
      );
    }
  }

  Future resume(String id) async {
    await _repository.resume(id);
  }

  Future delete(String id) async {
    if (state.importedModels.any((e) => e.id == id)) {
      final importedModels = await _repository.deleteImportedModel(id);
      emit(state.copyWith(importedModels: importedModels));
      return;
    }
    await _repository.deleteLocalModelFiles(id);
    _emitCatalogSnapshot(_repository.getCurrentCatalog());
  }

  Future cancel(String id) async {
    await _repository.cancel(id);
    emit(
      state.copyWith(
        modelStates: {...state.modelStates, id: null}
          ..removeWhere((k, v) => v == null),
      ),
    );
  }

  Future pause(String id) async {
    await _repository.pause(id);
  }

  Future updateModelList({bool local = true, bool remote = true}) async {
    if (remote) {
      final models = await _remoteServiceRepository.fetchRemoteModels(
        forceRefresh: true,
      );
      emit(state.copyWith(remoteModels: models));
    }

    if (local && !kIsWeb) {
      _emitCatalogSnapshot(await _repository.refreshLocalCatalog());
    }
  }

  Future<void> setDownloadSource(DownloadSource source) async {
    if (_managerInitialized) {
      await _repository.setDownloadSource(source);
    }
    emit(state.copyWith(downloadSource: source));
  }

  Future onImportModel(ModelInfo model) async {
    final importedModels = await _repository.saveImportedModel(model);
    emit(state.copyWith(importedModels: importedModels));
  }

  ModelInfo? findModelByMD5(String md5) {
    return state.allModels.where((e) => e.md5 == md5).firstOrNull;
  }

  void _emitTaskUpdate({
    required String modelId,
    required TaskUpdate update,
    Object? error,
  }) {
    logd(
      'download update: ${update.state}, ${update.progress.toStringAsFixed(2)}',
    );
    final models = update.isCompleted
        ? _repository.getCurrentCatalog().localModels
        : null;
    emit(
      state.copyWith(
        models: models,
        modelStates: {
          ...state.modelStates,
          modelId: update.isCompleted
              ? null
              : ModelDownloadState(update: update, error: error),
        }..removeWhere((k, v) => v == null || v.update.isCompleted),
      ),
    );
  }

  void _emitCatalogSnapshot(
    ModelCatalogSnapshot snapshot, {
    String? downloadDir,
  }) {
    emit(
      state.copyWith(
        models: snapshot.localModels,
        tags: snapshot.tags,
        groups: snapshot.groups,
        downloadDir: downloadDir ?? state.downloadDir,
        modelStates: {
          for (final entry in snapshot.taskUpdates.entries)
            entry.key: ModelDownloadState(update: entry.value, error: null),
        },
      ),
    );
  }

  @override
  Future<void> close() async {
    await _taskUpdateSubscription?.cancel();
    return super.close();
  }
}
