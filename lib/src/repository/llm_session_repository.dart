import 'dart:async';

import 'package:rwkv_dart/rwkv_dart.dart' hide ModelBaseInfo;
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_state.dart';
import 'package:rwkv_studio/src/bloc/llm/model_load_state.dart';
import 'package:rwkv_studio/src/component/rwkv_lightning.dart';
import 'package:rwkv_studio/src/component/rwkv_mobile.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/chat/chat_event.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/models/model/model_service_wrap.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/rwkv_tokenizer.dart';

class AlbatrossLaunchConfig {
  final Python? python;
  final String scriptPath;

  const AlbatrossLaunchConfig({this.python, required this.scriptPath});
}

class LlmSessionSnapshot {
  final Map<String, ModelInstanceState> models;

  const LlmSessionSnapshot({this.models = const {}});
}

class LlmSessionRepository {
  final _snapshotController = StreamController<LlmSessionSnapshot>.broadcast();
  final _subscriptions = <String, StreamSubscription>{};
  final _boundRwkvs = <String, RWKV>{};

  String _rwkvLightningEntryPoint = '';
  String _rwkvMobileEntryPoint = '';
  Map<String, ModelInstanceState> _models = const {};

  LlmSessionRepository();

  Map<String, ModelInstanceState> get models => _models;

  LlmSessionSnapshot get snapshot => LlmSessionSnapshot(models: _models);

  void setRwkvLightningEntryPoint(String path) {
    _rwkvLightningEntryPoint = path;
  }

  void setRwkvMobileEntryPoint(String path) {
    _rwkvMobileEntryPoint = path;
  }

  Stream<LlmSessionSnapshot> watchSnapshot() {
    return _snapshotController.stream;
  }

  ModelInstanceState? getModelInstance(String? instanceId) {
    if (instanceId == null || instanceId.isEmpty) {
      return null;
    }
    return _models[instanceId];
  }

  ModelInstanceState? getInstanceByModelId(String modelId) {
    return _models.values.where((e) => e.info.id == modelId).firstOrNull;
  }

  List<String> getLoadedInstance(String modelId) {
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

  int getTokenCount(String instanceId, String prompt) {
    final instance = _requireInstance(instanceId);
    // todo adapt non-rwkv models
    if (!instance.info.name.toLowerCase().contains("rwkv")) {
      return -1;
    }
    final tokens = RwkvTokenizer.default_.tokenCount(prompt);
    return tokens;
  }

  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) async* {
    RWKV rwkv;
    String? instanceId;

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
    } else if (modelInfo.backend == .albatross) {
      if (_rwkvLightningEntryPoint.isEmpty) {
        yield ModelLoadState.error(
          modelInfo.id,
          const AppException.configuration(
            'rwkv_lightning backend entry point is not initialize',
          ),
        );
        return;
      }
      rwkv = await RwkvLightningCpp.create(
        executable: _rwkvLightningEntryPoint,
      );
    } else if (_rwkvMobileEntryPoint.isNotEmpty) {
      rwkv = RwkvMobile(_rwkvMobileEntryPoint);
    } else {
      rwkv = RWKV.isolated();
    }

    await rwkv.init(InitParam(logLevel: RWKVLogLevel.verbose));
    yield ModelLoadState.loading(modelInfo.id);
    try {
      Backend? backend;
      if (modelInfo.backend == ModelBackend.web_rwkv) {
        backend = .webRwkv;
      }
      if (modelInfo.backend == ModelBackend.qnn) {
        backend = .qnn;
      }

      await rwkv.loadModel(
        LoadModelParam(
          modelPath: modelInfo.localPath,
          tokenizerPath: AppAssets.rwkvVocab20230424Path,
          backend: backend,
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

  Stream<ChatEvent> chat(
    List<ChatMessage> messages,
    String instanceId,
    DecodeParam decodeParam,
    GenerationConfig config, {
    McpChatRunner? mcpRunner,
  }) async* {
    final instance = _requireInstance(instanceId);

    await _syncModelConfig(instanceId, decodeParam);

    logi('llm chat: ${instance.info.name} ${instance.id}');

    if (mcpRunner != null && instance.info.supportFunctionCall) {
      yield* _chatWithMcp(
        instance: instance,
        mcpRunner: mcpRunner,
        messages: messages,
        decodeParam: decodeParam,
        config: config,
      );
      return;
    }

    try {
      final stream = instance.rwkv
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

      await for (final response in stream) {
        yield ChatAssistantEvent(
          reasoningDelta: response.reasoningContent,
          contentDelta: response.content,
          stopReason: response.stopReason,
          tokenCount: response.tokenCount,
        );
      }
    } catch (e, s) {
      loge(e, s);
      throw AppException.wrap(e, s);
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
            // stopTokens: [], // FOR TEST ONLY
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
      return;
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
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _boundRwkvs.clear();
    _models = const {};
    await _snapshotController.close();
  }

  Stream<ChatEvent> _chatWithMcp({
    required ModelInstanceState instance,
    required McpChatRunner mcpRunner,
    required List<ChatMessage> messages,
    required DecodeParam decodeParam,
    required GenerationConfig config,
  }) async* {
    final events = mcpRunner.run(
      messages: messages,
      maxTokens: decodeParam.maxTokens,
      prompt: config.prompt,
      reasoning: config.reasoningEffort,
    );

    await for (final event in events) {
      switch (event) {
        case McpAssistantEvent():
          if (event.reasoningDelta.isNotEmpty) {
            yield ChatAssistantEvent(
              reasoningDelta: event.reasoningDelta,
              stopReason: event.stopReason,
              round: event.rounds,
            );
          }
          if (event.delta.isNotEmpty) {
            yield ChatAssistantEvent(
              contentDelta: event.delta,
              stopReason: event.stopReason,
              round: event.rounds,
            );
          }
          if (event.isFinal) {
            yield ChatCompletedEvent(
              text: event.content,
              round: event.rounds,
              stopReason: event.stopReason,
            );
          }
        case McpToolCallEvent():
          yield ChatToolCallEvent(
            round: event.rounds,
            toolCall: event.toolCall,
          );
        case McpToolResultEvent():
          yield ChatToolResultEvent(
            round: event.rounds,
            result: event.toolResult,
          );
      }
    }
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

  void syncRemoteServiceInstances(Iterable<ModelServiceWrap> services) {
    final nextModels = Map<String, ModelInstanceState>.fromEntries(
      _models.entries.where((entry) => !entry.value.info.isRemote),
    );
    final remoteInstanceIds = <String>{};

    for (final service in services) {
      for (final loadedModel in service.models) {
        loadedModel.rwkv.setLogLevel(RWKVLogLevel.info);

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
