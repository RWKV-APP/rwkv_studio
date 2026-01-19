import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/model/remote_model.dart';
import 'package:rwkv_studio/src/network/http.dart';
import 'package:rwkv_studio/src/utils/file_util.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'model_manage_state.dart';

extension Ext on BuildContext {
  ModelManageCubit get modelManage => read<ModelManageCubit>();
}

class ModelManageCubit extends Cubit<ModelManageState> {
  late final ModelManager manager;

  ModelManageCubit() : super(ModelManageState.initial());

  Iterable<ModelInfo> get availableModels =>
      state.models.where((e) => e.localPath.isNotEmpty);

  void setModelProviders(List<RemoteModelProviderInfo> providers) {
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

    manager = ModelManager(
      downloadSource: DownloadSource.aiFastHub,
      configProviderUrl: 'http://localhost:8080/model_config.json',
      modelDownloadDir: 'models',
    );
    final tasks = await manager.init();

    manager.downloadUpdateEvents().listen((event) {
      _emitTaskUpdate(
        modelId: event.model.id,
        update: event.update,
        error: event.error,
      );
    });

    final models = manager.models;
    emit(
      state.copyWith(
        initialized: true,
        models: models,
        tags: manager.modelConfig.tags,
        groups: manager.modelConfig.groups,
        downloadSource: manager.downloadSource,
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
      await manager.download(id);
    } catch (e) {
      _emitTaskUpdate(
        modelId: id,
        update: TaskUpdate.initial().copyWith(state: TaskState.stopped),
        error: e,
      );
    }
  }

  void resume(String id) {
    manager.download(id);
  }

  Future delete(String id) async {
    await manager.deleteLocalModelFiles(id);
    emit(state.copyWith(models: manager.models));
  }

  Future cancel(String id) async {
    await manager.cancelTask(id);
    emit(state.copyWith(modelStates: {...state.modelStates, id: null}));
  }

  Future pause(String id) async {
    await manager.pauseTask(id);
  }

  Future updateModelList({bool local = true, bool remote = true}) async {
    List<ModelInfo> models = state.models.toList();
    if (remote) {
      models.removeWhere((e) => e is RemoteModelInfo);
      final providers = state.remoteModelProviders;
      for (final provider in providers) {
        try {
          final resp = await HTTP.get(provider.url);
          final list = (resp.data['models'] as Iterable).map((e) {
            return RemoteModelInfo.fromMap(e)
              ..providerName = provider.name
              ..serviceId = provider.serviceId;
          });
          models = [...list, ...models];
          logd(
            'synced ${list.length} models from ${provider.name} (${provider.url})',
          );
        } catch (e, s) {
          loge('failed to fetch models from ${provider.name}', e, s);
        }
      }
    }

    if (local) {
      models.removeWhere((e) => e is! RemoteModelInfo);
      await manager.updateConfig();
      models = [...models, ...manager.models];
    }
    emit(
      state.copyWith(
        models: models,
        tags: manager.modelConfig.tags,
        groups: manager.modelConfig.groups,
      ),
    );
  }

  void setDownloadSource(DownloadSource source) {
    manager.downloadSource = source;
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
    emit(state.copyWith(models: [model, ...manager.models]));
  }

  void _emitTaskUpdate({
    required String modelId,
    required TaskUpdate update,
    Object? error,
  }) {
    logd(
      'download update: ${update.state}, ${update.progress.toStringAsFixed(2)}',
    );
    final m = update.isCompleted ? manager.models : null;
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
