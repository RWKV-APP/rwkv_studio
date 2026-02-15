import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/cache/model_file_box.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

import 'model_provider.dart';

part 'model_manage_state.dart';

extension Ext on BuildContext {
  ModelManageCubit get modelManage => read<ModelManageCubit>();
}

class ModelManageCubit extends Cubit<ModelManageState> {
  late final ModelManager _manager;

  ModelManageCubit() : super(ModelManageState.initial());

  // TODO optimize
  Iterable<ModelInfo> get availableTextModels => state.models.where(
    (e) =>
        (e.localPath.isNotEmpty || e.isRemote) &&
        (e.groups.overlaps({'chat', 'albatross', 'roleplay'}) || e.isRemote),
  );

  void setModelProviders(List<ModelListProvider> providers) {
    emit(state.copyWith(remoteModelProviders: providers));
    updateModelList(local: false);
  }

  Future setModelDownloadDir(String path, {bool migration = false}) async {
    await _manager.setModelDownloadDir(path, migration: migration);
    await _manager.init();
    await updateModelList(remote: false);
  }

  Future init({required String modelDir, required String configUrl}) async {
    if (state.initialized) {
      logw('ModelManageCubit already initialized');
      return;
    }
    logi('ModelManageCubit init, modelDir: $modelDir, configUrl: $configUrl');

    if (kIsWeb) {
      return;
    }

    _manager = ModelManager(
      downloadSource: DownloadSource.aiFastHub,
      configProviderUrl: configUrl,
      modelDownloadDir: modelDir,
    );
    final tasks = await _manager.init();

    _manager.downloadUpdateEvents().listen((event) {
      _emitTaskUpdate(
        modelId: event.model.id,
        update: event.update,
        error: event.error,
      );
    });

    final models = _getModelList();

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
        models: models,
        importedModels: importedModels,
        tags: _manager.modelConfig.tags,
        groups: _manager.modelConfig.groups,
        backends: ModelBackend.defaultBackends,
        downloadSource: _manager.downloadSource,
        modelStates: {
          for (final entry in tasks.entries)
            entry.key: ModelDownloadState(
              update: entry.value.update,
              error: null,
            ),
        },
      ),
    );

    updateModelList(local: false);
  }

  Future updateModelConfigUrl(String url) async {
    _manager.setConfigProviderUrl(url);
    await updateModelList(remote: false);
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
    emit(state.copyWith(models: _getModelList()));
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
    List<ModelInfo> models = state.models.toList();
    if (remote) {
      models.removeWhere((e) => e.isRemote);
      final providers = state.remoteModelProviders;
      for (final provider in providers) {
        final list = await provider.getModelList();
        models = [...list, ...models];
      }
    }

    List<ModelTag> tags = [];
    List<ModelGroup> groups = [];

    if (local && !kIsWeb) {
      models.removeWhere((e) => !e.isRemote);
      await _manager.updateConfig();
      models = [...models, ..._getModelList()];
    }

    if (!kIsWeb) {
      tags = _manager.modelConfig.tags;
      groups = _manager.modelConfig.groups;
    }

    emit(state.copyWith(models: models, tags: tags, groups: groups));
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
          ..._getModelList(),
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
    final m = update.isCompleted ? _getModelList() : null;
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

  List<ModelInfo> _getModelList() {
    return _manager.models.where((e) {
      if (e.groups.contains('othello') || e.groups.contains('sudoku')) {
        return false;
      }
      return true;
    }).toList();
  }
}
