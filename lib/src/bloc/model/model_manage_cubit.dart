import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/cache/model_file_box.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

import 'model_provider.dart';

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
  late final ModelManager _manager;
  bool _managerInitialized = false;

  ModelManageCubit() : super(ModelManageState.initial());

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
    if (kIsWeb) {
      return;
    }
    _manager = ModelManager(
      downloadSource: state.downloadSource,
      configProviderUrl: configProviderUrl,
      modelDownloadDir: modelDownloadDir,
    );
    _manager.downloadUpdateEvents().listen((event) {
      _emitTaskUpdate(
        modelId: event.model.id,
        update: event.update,
        error: event.error,
      );
    });
    await _manager.init();
    emit(
      state.copyWith(
        models: _manager.enabledModels,
        tags: _manager.modelConfig.tags,
        groups: _manager.modelConfig.groups,
        modelStates: {
          for (final entry in _manager.downloadTasks.entries)
            entry.key: ModelDownloadState(
              update: entry.value.update,
              error: null,
            ),
        },
      ),
    );
    _managerInitialized = true;
  }

  void setModelProviders(List<ModelListProvider> providers) {
    emit(state.copyWith(remoteModelProviders: providers));
    if (kIsWeb) {
      return;
    }
    updateModelList(local: false);
  }

  Future setModelDownloadDir(String path, {bool migration = false}) async {
    if (!_managerInitialized) {
      return;
    }
    await _manager.setModelDownloadDir(path, migration: migration);
    await updateModelList(remote: false);
  }

  Future updateModelConfigUrl(String url) async {
    if (kIsWeb || !_managerInitialized) {
      return;
    }
    _manager.setConfigProviderUrl(url);
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

    List<ModelInfo> importedModels = [];
    try {
      await HiveManager.openModelFileBox();
      importedModels = ModelFileBox.getAllModels().toList();
    } catch (e) {
      logw(e);
    }
    emit(
      state.copyWith(
        initialized: true,
        importedModels: importedModels,
        backends: ModelBackend.defaultBackends,
      ),
    );
  }

  Future download(String id) async {
    try {
      await _manager.download(id);
    } catch (e) {
      _emitTaskUpdate(
        modelId: id,
        update: TaskUpdate.initial().copyWith(state: TaskState.stopped),
        error: e,
      );
    }
  }

  Future resume(String id) async {
    await _manager.download(id);
  }

  Future delete(String id) async {
    if (state.importedModels.any((e) => e.id == id)) {
      await ModelFileBox.delete(id);
      emit(
        state.copyWith(importedModels: ModelFileBox.getAllModels().toList()),
      );
      return;
    }
    await _manager.deleteLocalModelFiles(id);
    emit(state.copyWith(models: _manager.enabledModels));
  }

  Future cancel(String id) async {
    _manager.cancelTask(id);
    emit(
      state.copyWith(
        modelStates: {...state.modelStates, id: null}
          ..removeWhere((k, v) => v == null),
      ),
    );
  }

  Future pause(String id) async {
    await _manager.pauseTask(id);
  }

  Future updateModelList({bool local = true, bool remote = true}) async {
    if (remote) {
      List<ModelInfo> models = [];
      final providers = state.remoteModelProviders;
      for (final provider in providers) {
        final list = await provider.getModelList().wrapError();
        models = [...list, ...models];
      }
      emit(state.copyWith(remoteModels: models));
    }

    if (local && !kIsWeb) {
      await _manager.updateConfig();
      emit(
        state.copyWith(
          models: _manager.enabledModels,
          tags: _manager.modelConfig.tags,
          groups: _manager.modelConfig.groups,
          modelStates: {
            for (final entry in _manager.downloadTasks.entries)
              entry.key: ModelDownloadState(
                update: entry.value.update,
                error: null,
              ),
          },
        ),
      );
    }
  }

  void setDownloadSource(DownloadSource source) {
    _manager.downloadSource = source;
    emit(state.copyWith(downloadSource: source));
  }

  Future onImportModel(ModelInfo model) async {
    await ModelFileBox.put(model);

    emit(
      state.copyWith(
        models: [
          model.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString()),
          ..._manager.enabledModels,
        ],
      ),
    );
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
    final m = update.isCompleted ? _manager.enabledModels : null;
    emit(
      state.copyWith(
        models: m,
        modelStates: {
          ...state.modelStates,
          modelId: update.isCompleted
              ? null
              : ModelDownloadState(update: update, error: error),
        }..removeWhere((k, v) => v == null || v.update.isCompleted),
      ),
    );
  }
}
