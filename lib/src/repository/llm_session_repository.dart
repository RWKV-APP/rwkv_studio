import 'dart:async';

import 'package:rwkv_dart/rwkv_dart.dart' hide ModelBaseInfo;
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/model_load_state.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_state.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/python/albatross.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/repository/remote_service_repository.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class AlbatrossLaunchConfig {
  final Python python;
  final String scriptPath;

  const AlbatrossLaunchConfig({required this.python, required this.scriptPath});
}

class LlmSessionSnapshot {
  final Map<String, ModelInstanceState> models;

  const LlmSessionSnapshot({this.models = const {}});
}

class LlmSessionRepository {
  final RemoteServiceRepository _remoteServiceRepository;
  final _snapshotController = StreamController<LlmSessionSnapshot>.broadcast();
  final _subscriptions = <String, StreamSubscription>{};
  final _boundRwkvs = <String, RWKV>{};
  late final StreamSubscription<RemoteServiceSnapshot>
  _remoteServiceSubscription;

  Map<String, ModelInstanceState> _models = const {};

  LlmSessionRepository(this._remoteServiceRepository) {
    _remoteServiceSubscription = _remoteServiceRepository
        .watchSnapshot()
        .listen(_syncRemoteServiceInstances);
    _syncRemoteServiceInstances(_remoteServiceRepository.snapshot);
  }

  Map<String, ModelInstanceState> get models => _models;

  LlmSessionSnapshot get snapshot => LlmSessionSnapshot(models: _models);

  Stream<LlmSessionSnapshot> watchSnapshot() {
    return _snapshotController.stream;
  }

  ModelInstanceState? getModelInstance(String? instanceId) {
    if (instanceId == null || instanceId.isEmpty) {
      return null;
    }
    return _models[instanceId];
  }

  Future<List<String>> getLoadedInstance(String modelId) async {
    return _models.values
        .where((e) => e.info.id == modelId)
        .map((e) => e.id)
        .toList();
  }

  Future<ModelBaseInfo> getModelBaseInfo(String instanceId) async {
    return _requireInstance(instanceId).info;
  }

  Future<void> stop(String instanceId) async {
    logd('stop $instanceId');
    final instance = _requireInstance(instanceId);
    if (!instance.state.isGenerating) {
      logw('not generating');
    }
    await instance.rwkv.stopGenerate();
  }

  Future<void> setDecodeParam(String instanceId, DecodeParam param) async {
    await _syncModelConfig(instanceId, param);
  }

  Future<void> release(String instanceId) async {
    final instance = _requireInstance(instanceId);
    await instance.rwkv.release();
    _detachGenerationState(instanceId);
    _models = {..._models}..remove(instanceId);
    logd('model released $instanceId');
    _emitSnapshot();
  }

  Stream<ModelLoadState> loadModel(
    ModelInfo modelInfo, {
    AlbatrossLaunchConfig? albatrossConfig,
  }) async* {
    RWKV rwkv;
    String? instanceId;

    if (modelInfo.backend == ModelBackend.albatross && !modelInfo.isRemote) {
      if (albatrossConfig == null) {
        yield ModelLoadState.error(
          modelInfo.id,
          const AppException.configuration('Missing Albatross launch config'),
        );
        return;
      }
      try {
        yield ModelLoadState.loading(modelInfo.id);
        rwkv = await _startAlbatross(albatrossConfig, modelInfo);
      } catch (e, s) {
        yield ModelLoadState.error(modelInfo.id, AppException.wrap(e, s));
        return;
      }
      instanceId = modelInfo.id;
      final instance = ModelInstanceState(
        rwkv: rwkv,
        id: instanceId,
        info: ModelBaseInfo.fromModelInfo(modelInfo),
      );
      _upsertInstance(instance);
      yield ModelLoadState.loaded(
        modelInfo.id,
        modelInfo.name,
        instance.id,
        modelInfo.providerName,
      );
      return;
    }

    if (modelInfo.isRemote) {
      final model = _models[modelInfo.id];
      if (model == null) {
        yield ModelLoadState.error(
          modelInfo.id,
          AppException.notFound(
            'Remote model not found from ${modelInfo.providerName}: ${modelInfo.id}',
          ),
        );
        return;
      }
      rwkv = model.rwkv;
      instanceId = model.info.id;
    } else {
      rwkv = RWKV.isolated();
    }

    await rwkv.init(InitParam(logLevel: RWKVLogLevel.verbose));
    yield ModelLoadState.loading(modelInfo.id);
    try {
      await rwkv.loadModel(
        LoadModelParam(
          modelPath: modelInfo.localPath,
          tokenizerPath: AppAssets.rwkvVocab20230424Path,
        ),
      );
    } catch (e, s) {
      yield ModelLoadState.error(modelInfo.id, AppException.wrap(e, s));
      return;
    }

    final previous = instanceId == null ? null : _models[instanceId];
    final instance = ModelInstanceState(
      rwkv: rwkv,
      id: instanceId ?? 'local_${modelInfo.id}',
      info: ModelBaseInfo.fromModelInfo(modelInfo),
      state: previous?.state,
      config: previous?.config,
      decodeParam: previous?.decodeParam,
    );
    _upsertInstance(instance);
    yield ModelLoadState.loaded(
      modelInfo.id,
      modelInfo.name,
      instance.id,
      modelInfo.providerName,
    );
  }

  Stream<GenerationResponse> chat(
    List<ChatMessage> messages,
    String instanceId,
    DecodeParam decodeParam,
    GenerationConfig config,
  ) async* {
    final instance = _requireInstance(instanceId);

    await _syncModelConfig(instanceId, decodeParam);

    logi('chat: ${instance.id}');
    try {
      yield* instance.rwkv
          .chat(
            ChatParam(
              messages: messages,
              model: instanceId,
              maxTokens: decodeParam.maxTokens,
              prompt: config.prompt,
              stopSequence: config.stopTokens,
              reasoning: config.reasoningEffort,
            ),
          )
          .timeout(const Duration(seconds: 60));
    } catch (e, s) {
      loge(e, s);
      rethrow;
    }
  }

  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    DecodeParam decodeParam, {
    int batch = 1,
    String? fimSuffix,
  }) async* {
    final instance = _requireInstance(instanceId).rwkv;

    await _syncModelConfig(instanceId, decodeParam);
    await instance.clearState();

    if (batch > 1) {
      if (instance is AlbatrossClient) {
        yield* instance.chatV2Stream(
          ChatRequest(
            contents: [for (int i = 0; i < batch; i++) prompt],
            stopTokens: [0, 261],
            maxTokens: decodeParam.maxTokens,
          ),
        );
        return;
      }
      throw const AppException.unsupported(
        'Batch inference is only supported by Albatross',
      );
    }

    if (fimSuffix != null) {
      if (instance is AlbatrossClient) {
        yield* instance.fimBatchStream(
          FimRequest(
            prefix: [prompt],
            suffix: [fimSuffix],
            maxTokens: decodeParam.maxTokens,
          ),
        );
      } else {
        throw const AppException.unsupported(
          'FIM is only supported by Albatross',
        );
      }
    }

    logi('start generate: $prompt');

    try {
      yield* instance
          .generate(
            GenerationParam(
              prompt: prompt,
              model: instanceId,
              maxCompletionTokens: decodeParam.maxTokens,
            ),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e, s) {
      loge(e, s);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _remoteServiceSubscription.cancel();
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _boundRwkvs.clear();
    _models = const {};
    await _snapshotController.close();
  }

  Future<AlbatrossClient> _startAlbatross(
    AlbatrossLaunchConfig config,
    ModelInfo model,
  ) {
    final cmd = AlbatrossLauncher(
      python: config.python,
      scriptPath: config.scriptPath,
      modelPath: model.localPath,
    );
    return cmd.startup();
  }

  Future<void> _syncModelConfig(
    String instanceId,
    DecodeParam decodeParam,
  ) async {
    ModelInstanceState instance = _requireInstance(instanceId);
    var updated = false;

    if (instance.decodeParam != decodeParam) {
      await instance.rwkv.setDecodeParam(decodeParam);
      instance = instance.copyWith(decodeParam: decodeParam);
      updated = true;
    }
    if (updated) {
      _models = {..._models, instanceId: instance};
      _emitSnapshot();
    }
  }

  void _syncRemoteServiceInstances(RemoteServiceSnapshot snapshot) {
    final nextModels = Map<String, ModelInstanceState>.fromEntries(
      _models.entries.where((entry) => !entry.value.info.isRemote),
    );
    final remoteInstanceIds = <String>{};

    for (final service in snapshot.services) {
      for (final loadedModel in service.models) {
        final instanceId = loadedModel.info.id;
        remoteInstanceIds.add(instanceId);
        final previous = _models[instanceId];
        nextModels[instanceId] = ModelInstanceState(
          rwkv: loadedModel.rwkv,
          id: instanceId,
          info: ModelBaseInfo.remote(
            id: loadedModel.info.id,
            name: loadedModel.info.name,
            providerName: service.sourceName,
            serviceId: service.id,
          ),
          state: previous?.state,
          config: previous?.config,
          decodeParam: previous?.decodeParam,
        );
        _bindGenerationState(instanceId, loadedModel.rwkv);
        logd('model added: ${service.url} ${loadedModel.info.name}');
      }
    }

    for (final entry in _models.entries) {
      if (entry.value.info.isRemote && !remoteInstanceIds.contains(entry.key)) {
        _detachGenerationState(entry.key);
      }
    }

    _models = nextModels;
    logd('synced ${remoteInstanceIds.length} remote instance(s)');
    _emitSnapshot();
  }

  void _upsertInstance(ModelInstanceState instance) {
    _models = {..._models, instance.id: instance};
    _bindGenerationState(instance.id, instance.rwkv);
    _emitSnapshot();
  }

  void _bindGenerationState(String instanceId, RWKV rwkv) {
    if (_boundRwkvs[instanceId] == rwkv) {
      return;
    }
    _detachGenerationState(instanceId);
    _boundRwkvs[instanceId] = rwkv;
    _subscriptions[instanceId] = rwkv.generationStateStream().listen((state) {
      final instance = _models[instanceId];
      if (instance == null || instance.state == state) {
        return;
      }
      _models = {..._models, instanceId: instance.copyWith(state: state)};
      _emitSnapshot();
    });
  }

  void _detachGenerationState(String instanceId) {
    _boundRwkvs.remove(instanceId);
    _subscriptions.remove(instanceId)?.cancel();
  }

  void _emitSnapshot() {
    if (_snapshotController.isClosed) {
      return;
    }
    _snapshotController.add(snapshot);
  }

  ModelInstanceState _requireInstance(String instanceId) {
    final instance = _models[instanceId];
    if (instance == null) {
      throw AppException.notFound('Model instance not found: $instanceId');
    }
    return instance;
  }
}
