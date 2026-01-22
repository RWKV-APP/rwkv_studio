import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/utils/file_util.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

import 'model_provider.dart';

part 'model_manage_state.dart';

extension Ext on BuildContext {
  ModelManageCubit get modelManage => read<ModelManageCubit>();
}

class ModelManageCubit extends Cubit<ModelManageState> {
  late final ModelManager _manager;

  ModelManageCubit() : super(ModelManageState.initial());

  Iterable<ModelInfo> get availableModels =>
      state.models.where((e) => e.localPath.isNotEmpty || e.isRemote);

  void setModelProviders(List<ModelListProvider> providers) {
    emit(state.copyWith(remoteModelProviders: providers));
    updateModelList(local: false);
  }

  Future init() async {
    if (state.initialized) {
      logw('ModelManageCubit already initialized');
      return;
    }
    logi('ModelManageCubit init');

    if (kIsWeb) {
      return;
    }

    _manager = ModelManager(
      downloadSource: DownloadSource.aiFastHub,
      configProviderUrl: 'http://localhost:8080/model_config.json',
      modelDownloadDir: 'models',
    );
    final tasks = await _manager.init();

    _manager.downloadUpdateEvents().listen((event) {
      _emitTaskUpdate(
        modelId: event.model.id,
        update: event.update,
        error: event.error,
      );
    });

    final models = _manager.models;
    emit(
      state.copyWith(
        initialized: true,
        models: models,
        tags: _manager.modelConfig.tags,
        groups: _manager.modelConfig.groups,
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

  void download(String id) async {
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

  void resume(String id) {
    _manager.download(id);
  }

  Future delete(String id) async {
    await _manager.deleteLocalModelFiles(id);
    emit(state.copyWith(models: _manager.models));
  }

  Future cancel(String id) async {
    await _manager.cancelTask(id);
    emit(state.copyWith(modelStates: {...state.modelStates, id: null}));
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
      models = [...models, ..._manager.models];
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

  Future importModel(String path) async {
    final file = File(path);
    final size = await file.length();
    final sha256 = ''; // await file.sha256();
    final md5 = await file.md5();

    final model = ModelInfo.base(
      id: sha256,
      name: file.name,
      url: path,
      fileSize: size,
      backend: ModelBackend.conjecture(file.extension) ?? ModelBackend.unknown,
      sha256: sha256,
      md5: md5,
      localPath: path,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    emit(state.copyWith(models: [model, ..._manager.models]));
  }

  void _emitTaskUpdate({
    required String modelId,
    required TaskUpdate update,
    Object? error,
  }) {
    logd(
      'download update: ${update.state}, ${update.progress.toStringAsFixed(2)}',
    );
    final m = update.isCompleted ? _manager.models : null;
    emit(
      state.copyWith(
        models: m,
        modelStates: {
          ...state.modelStates,
          modelId: ModelDownloadState(update: update, error: error),
        },
      ),
    );
  }
}
