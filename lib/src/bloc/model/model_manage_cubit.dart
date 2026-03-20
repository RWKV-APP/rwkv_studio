import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/model/model_identity.dart';
import 'package:rwkv_studio/src/repository/model_manager_repository.dart';
import 'package:rwkv_studio/src/repository/remote_service_repository.dart';
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

class _ModelManagerRuntimeConfig {
  final String modelDownloadDir;
  final String configProviderUrl;
  final DownloadSource downloadSource;

  const _ModelManagerRuntimeConfig({
    required this.modelDownloadDir,
    required this.configProviderUrl,
    required this.downloadSource,
  });
}

class ModelManageCubit extends Cubit<ModelManageState> {
  final ModelManagerRepository _repository;
  final RemoteServiceRepository _remoteServiceRepository;
  StreamSubscription<ModelTaskUpdateEvent>? _taskUpdateSubscription;
  late final StreamSubscription<RemoteServiceSnapshot>
  _remoteServiceSnapshotSubscription;
  Future<void>? _runtimeInitFuture;
  _ModelManagerRuntimeConfig? _desiredRuntimeConfig;
  _ModelManagerRuntimeConfig? _appliedRuntimeConfig;

  ModelManageCubit(this._repository, this._remoteServiceRepository)
    : super(ModelManageState.initial()) {
    _remoteServiceSnapshotSubscription = _remoteServiceRepository
        .watchSnapshot()
        .listen((snapshot) {
          emit(state.copyWith(remoteModels: snapshot.remoteModels));
        });
  }

  Future<void> ensureRuntimeReady() async {
    if (kIsWeb) {
      return;
    }
    if (_repository.isInitialized) {
      if (!state.runtimeReady ||
          state.runtimeLoading ||
          state.runtimeError.isNotEmpty) {
        emit(
          state.copyWith(
            runtimeReady: true,
            runtimeLoading: false,
            runtimeError: '',
          ),
        );
      }
      return;
    }
    _runtimeInitFuture ??= _initializeRuntime().whenComplete(() {
      _runtimeInitFuture = null;
    });
    await _runtimeInitFuture;
  }

  void setRuntimeConfig({
    required String modelDownloadDir,
    required String configProviderUrl,
    DownloadSource? downloadSource,
  }) {
    if (kIsWeb) {
      return;
    }
    final desired = _ModelManagerRuntimeConfig(
      modelDownloadDir: modelDownloadDir,
      configProviderUrl: configProviderUrl,
      downloadSource: downloadSource ?? state.downloadSource,
    );
    _desiredRuntimeConfig = desired;
    emit(
      state.copyWith(
        downloadDir: desired.modelDownloadDir,
        downloadSource: desired.downloadSource,
      ),
    );
  }

  Future<void> syncRuntimeConfig({
    required String modelDownloadDir,
    required String configProviderUrl,
    DownloadSource? downloadSource,
    bool migration = false,
    bool refreshLocalCatalog = false,
  }) async {
    if (kIsWeb) {
      return;
    }
    setRuntimeConfig(
      modelDownloadDir: modelDownloadDir,
      configProviderUrl: configProviderUrl,
      downloadSource: downloadSource,
    );
    final desired = _requireRuntimeConfig();
    await ensureRuntimeReady();

    final previous = _appliedRuntimeConfig;
    if (previous == null) {
      return;
    }

    final downloadDirChanged =
        previous.modelDownloadDir != desired.modelDownloadDir;
    final configUrlChanged =
        previous.configProviderUrl != desired.configProviderUrl;
    final downloadSourceChanged =
        previous.downloadSource != desired.downloadSource;
    if (!downloadDirChanged && !configUrlChanged && !downloadSourceChanged) {
      return;
    }

    await _repository.updateRuntimeConfig(
      modelDownloadDir: downloadDirChanged ? desired.modelDownloadDir : null,
      migration: migration,
      configProviderUrl: configUrlChanged ? desired.configProviderUrl : null,
      downloadSource: downloadSourceChanged ? desired.downloadSource : null,
    );
    _appliedRuntimeConfig = desired;

    if (downloadDirChanged || configUrlChanged || refreshLocalCatalog) {
      _emitCatalogSnapshot(
        await _repository.refreshLocalCatalog(),
        downloadDir: desired.modelDownloadDir,
        runtimeReady: true,
      );
      return;
    }

    emit(
      state.copyWith(
        runtimeReady: true,
        runtimeLoading: false,
        runtimeError: '',
        downloadDir: desired.modelDownloadDir,
        downloadSource: desired.downloadSource,
      ),
    );
  }

  Future setModelDownloadDir(String path, {bool migration = false}) async {
    final config = _requireRuntimeConfig();
    logd('Model download dir set to $path, updating model list');
    if (!_repository.isInitialized) {
      setRuntimeConfig(
        modelDownloadDir: path,
        configProviderUrl: config.configProviderUrl,
        downloadSource: config.downloadSource,
      );
      return;
    }
    await syncRuntimeConfig(
      modelDownloadDir: path,
      configProviderUrl: config.configProviderUrl,
      downloadSource: config.downloadSource,
      migration: migration,
      refreshLocalCatalog: true,
    );
  }

  Future updateModelConfigUrl(String url) async {
    if (kIsWeb) {
      return;
    }
    final config = _requireRuntimeConfig();
    if (!_repository.isInitialized) {
      setRuntimeConfig(
        modelDownloadDir: config.modelDownloadDir,
        configProviderUrl: url,
        downloadSource: config.downloadSource,
      );
      return;
    }
    await syncRuntimeConfig(
      modelDownloadDir: config.modelDownloadDir,
      configProviderUrl: url,
      downloadSource: config.downloadSource,
      refreshLocalCatalog: true,
    );
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
    } catch (e, s) {
      logw(AppException.wrap(e, s));
    }

    List<ModelIdentity> disabledModelIds = [];
    try {
      disabledModelIds = await _repository.getDisabledIdentity();
    } catch (e, s) {
      logw(AppException.wrap(e, s));
    }
    emit(
      state.copyWith(
        initialized: true,
        runtimeLoading: false,
        importedModels: importedModels,
        disabledModelIds: disabledModelIds,
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
      await ensureRuntimeReady();
      await _repository.download(id);
    } catch (e, s) {
      final error = AppException.wrap(e, s);
      _emitTaskUpdate(
        modelId: id,
        update: TaskUpdate.initial().copyWith(state: TaskState.stopped),
        error: error,
      );
      Error.throwWithStackTrace(error, error.stackTrace ?? s);
    }
  }

  Future resume(String id) async {
    await ensureRuntimeReady();
    await _repository.resume(id);
  }

  Future delete(String id) async {
    if (state.importedModels.any((e) => e.id == id)) {
      final importedModels = await _repository.deleteImportedModel(id);
      emit(state.copyWith(importedModels: importedModels));
      return;
    }
    await ensureRuntimeReady();
    await _repository.deleteLocalModelFiles(id);
    _emitCatalogSnapshot(_repository.getCurrentCatalog());
  }

  Future cancel(String id) async {
    await ensureRuntimeReady();
    await _repository.cancel(id);
    emit(
      state.copyWith(
        modelStates: {...state.modelStates, id: null}
          ..removeWhere((k, v) => v == null),
      ),
    );
  }

  Future pause(String id) async {
    await ensureRuntimeReady();
    await _repository.pause(id);
  }

  Future updateModelList({bool local = true, bool remote = true}) async {
    if (remote) {
      await _remoteServiceRepository
          .fetchRemoteModels(forceRefresh: true)
          .onError((e, s) {
            loge('update failed', e, s);
            return [];
          });
    }

    if (local && !kIsWeb) {
      await ensureRuntimeReady();
      _emitCatalogSnapshot(
        await _repository.refreshLocalCatalog(),
        downloadDir:
            _desiredRuntimeConfig?.modelDownloadDir ?? state.downloadDir,
        runtimeReady: true,
      );
    }
  }

  Future<void> setDownloadSource(DownloadSource source) async {
    emit(state.copyWith(downloadSource: source));
    if (kIsWeb) {
      return;
    }
    final config = _desiredRuntimeConfig;
    if (config == null) {
      return;
    }
    if (!_repository.isInitialized) {
      setRuntimeConfig(
        modelDownloadDir: config.modelDownloadDir,
        configProviderUrl: config.configProviderUrl,
        downloadSource: source,
      );
      return;
    }
    await syncRuntimeConfig(
      modelDownloadDir: config.modelDownloadDir,
      configProviderUrl: config.configProviderUrl,
      downloadSource: source,
    );
  }

  void setDisabledModels(List<ModelIdentity> ids) {
    _repository.setDisabledModels(ids);
    emit(state.copyWith(disabledModelIds: ids));
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
        runtimeReady: update.isCompleted ? true : state.runtimeReady,
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
    bool? runtimeReady,
  }) {
    emit(
      state.copyWith(
        runtimeReady: runtimeReady ?? state.runtimeReady,
        runtimeLoading: false,
        runtimeError: '',
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

  Future<void> _initializeRuntime() async {
    final config = _requireRuntimeConfig();
    emit(state.copyWith(runtimeLoading: true, runtimeError: ''));
    try {
      await _repository.ensureInitialized(
        modelDownloadDir: config.modelDownloadDir,
        configProviderUrl: config.configProviderUrl,
        downloadSource: config.downloadSource,
      );
      _bindTaskUpdateSubscription();
      _appliedRuntimeConfig = config;
      _emitCatalogSnapshot(
        _repository.getCurrentCatalog(),
        downloadDir: config.modelDownloadDir,
        runtimeReady: true,
      );
    } catch (e, s) {
      final error = AppException.wrap(e, s);
      emit(
        state.copyWith(
          runtimeReady: false,
          runtimeLoading: false,
          runtimeError: error.displayMessage,
        ),
      );
      Error.throwWithStackTrace(error, error.stackTrace ?? s);
    }
  }

  void _bindTaskUpdateSubscription() {
    if (_taskUpdateSubscription != null) {
      return;
    }
    _taskUpdateSubscription = _repository.watchTaskUpdates().listen(
      (event) {
        _emitTaskUpdate(
          modelId: event.modelId,
          update: event.update,
          error: event.error,
        );
      },
      onError: (e, s) {
        loge(AppException.wrap(e, s));
      },
    );
  }

  _ModelManagerRuntimeConfig _requireRuntimeConfig() {
    final config = _desiredRuntimeConfig;
    if (config == null) {
      throw const AppException.configuration(
        'Model manager runtime config has not been provided',
      );
    }
    return config;
  }

  @override
  Future<void> close() async {
    await _taskUpdateSubscription?.cancel();
    await _remoteServiceSnapshotSubscription.cancel();
    return super.close();
  }
}
