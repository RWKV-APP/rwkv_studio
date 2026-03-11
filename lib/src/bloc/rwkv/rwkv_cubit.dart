import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/model/model_service_wrap.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/repository/decode_param_repository.dart';
import 'package:rwkv_studio/src/repository/remote_service_repository.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'rwkv_state.dart';

extension Ext on BuildContext {
  RwkvCubit get rwkv => BlocProvider.of<RwkvCubit>(this);

  RwkvState get rwkvState => rwkv.state;
}

class RwkvCubit extends Cubit<RwkvState> with RwkvInterface {
  final DecodeParamRepository _decodeParamRepository;
  final RemoteServiceRepository _remoteServiceRepository;
  late final StreamSubscription<RemoteServiceSnapshot>
  _remoteServiceSubscription;

  RwkvCubit(this._decodeParamRepository, this._remoteServiceRepository)
    : super(RwkvState.initial()) {
    _remoteServiceSubscription = _remoteServiceRepository
        .watchSnapshot()
        .listen(_syncRemoteServiceInstances);
  }

  Future init() async {
    logd('init rwkv');

    final decodeParams = await _decodeParamRepository.getAll();
    logi(
      'restore decode params(${decodeParams.length}): ${decodeParams.keys.join(',')}',
    );
    emit(
      state.copyWith(
        decodeParams: {'default': DecodeParam.initial(), ...decodeParams},
      ),
    );
  }

  Future<void> setOrPutDecodeParam(String id, DecodeParam param) async {
    id = id.isEmpty ? 'default' : id;
    await _decodeParamRepository.put(id, param);
    emit(state.copyWith(decodeParams: {...state.decodeParams, id: param}));
  }

  Future<void> deleteDecodeParam(String id) async {
    logd('delete decode param $id');
    final params = {...state.decodeParams};
    params.remove(id);
    await _decodeParamRepository.delete(id);
    emit(state.copyWith(decodeParams: params));
  }

  void _syncRemoteServiceInstances(RemoteServiceSnapshot snapshot) {
    final instances = <String, ModelInstanceState>{};
    for (final service in snapshot.services) {
      final ms = service.models;
      for (final m in ms) {
        final modelId = m.info.id;
        instances[modelId] = ModelInstanceState(
          rwkv: m.rwkv,
          id: modelId,
          info: ModelBaseInfo.fromRemoteService(service, m),
        );
        logd('model added: ${service.url} ${m.info.name}');
      }
    }

    final localModels = Map<String, ModelInstanceState>.fromEntries(
      state.models.entries.where((entry) => !entry.value.info.isRemote),
    );
    logd('synced ${instances.length} remote instance(s)');
    emit(state.copyWith(models: {...localModels, ...instances}));
  }

  ModelInstanceState? getModelInstance(String? modelInstanceId) {
    return state.models[modelInstanceId];
  }

  @override
  Future<List<String>> getLoadedInstance(String modelId) async {
    return state.models.values
        .where((e) => e.info.id == modelId)
        .map((e) => e.id)
        .toList();
  }

  @override
  Future stop(String instanceId) async {
    logd('stop $instanceId');
    final instance = state.models[instanceId]!;
    if (!instance.state.isGenerating) {
      logw('not generating');
    }
    await instance.rwkv.stopGenerate();
  }

  Future setDecodeParam(String modelInstanceId, DecodeParam param) async {
    final instance = state.models[modelInstanceId]!;
    await instance.rwkv.setDecodeParam(param);
  }

  @override
  Stream<GenerationResponse> chat(
    List<ChatMessage> message,
    String instanceId,
    String decodeParamId,
    GenerationConfig config,
  ) async* {
    final instance = state.models[instanceId];
    if (instance == null) throw "Model not found";
    final param = decodeParamId.isEmpty
        ? DecodeParam.initial()
        : state.decodeParams[decodeParamId];
    if (param == null) throw "decode param preset not found: $decodeParamId";

    logi(
      'chat: instance:$instanceId, decode:$decodeParamId, reasoning:${config.reasoningEffort}, prompt:${config.prompt}',
    );

    await _syncModelConfig(instanceId, param, config);
    try {
      yield* instance.rwkv
          .chat(ChatParam(messages: message, model: instanceId))
          .timeout(const Duration(seconds: 60));
    } catch (e, s) {
      loge(e);
      loge(s);
      rethrow;
    }
  }

  @override
  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    String decodeParamId, {
    int batch = 1,
    String? fimSuffix,
  }) async* {
    final instance = state.models[instanceId]?.rwkv;
    if (instance == null) throw AppException('model not found $instanceId');
    final decodeParam = decodeParamId.isEmpty
        ? DecodeParam.initial()
        : state.decodeParams[decodeParamId];
    if (decodeParam == null) {
      throw AppException('decode param not found $decodeParamId');
    }
    await _syncModelConfig(instanceId, decodeParam, null);
    await instance.clearState();

    if (batch > 1) {
      if (instance is AlbatrossClient) {
        yield* instance.chatV2Stream(
          ChatRequest(
            contents: [for (int i = 0; i < batch; i++) prompt],
            stopTokens: [0, 261],
          ),
        );
        return;
      } else {
        throw const AppException('batch only implemented by albatross');
      }
    }

    if (fimSuffix != null) {
      if (instance is AlbatrossClient) {
        final stream = instance.fimBatchStream(
          FimRequest(prefix: [prompt], suffix: [fimSuffix]),
        );
        yield* stream;
      } else {
        throw const AppException('fim only supported by albatross');
      }
    }

    try {
      yield* instance
          .generate(GenerationParam(prompt: prompt, model: instanceId))
          .timeout(const Duration(seconds: 30));
    } catch (e, s) {
      loge(e);
      loge(s);
      rethrow;
    }
  }

  Future release(String modelInstanceId) async {
    final instance = state.models[modelInstanceId];
    if (instance == null) throw "Model not found";
    await instance.rwkv.release();
    logd('model released $modelInstanceId');
    emit(state.copyWith(models: {...state.models}..remove(modelInstanceId)));
  }

  @override
  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) async* {
    RWKV rwkv;
    String? instanceId;
    if (modelInfo.isRemote) {
      final model = state.models[modelInfo.id];
      if (model == null) {
        yield ModelLoadState.error(
          modelInfo.id,
          "no model found from ${modelInfo.providerName}, id: ${modelInfo.id}",
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
          tokenizerPath: AppAssets.rwkvVocab20230424,
        ),
      );
    } catch (e) {
      yield ModelLoadState.error(modelInfo.id, e);
      return;
    }
    final instance = ModelInstanceState(
      rwkv: rwkv,
      id: instanceId ?? "local_${modelInfo.id}",
      info: ModelBaseInfo.fromModelInfo(modelInfo),
    );
    emit(state.copyWith(models: {...state.models, instance.id: instance}));
    yield ModelLoadState.loaded(
      modelInfo.id,
      modelInfo.name,
      instance.id,
      modelInfo.providerName,
    );
    rwkv.generationStateStream().listen((e) {
      final inst = state.models[instance.id];
      if (inst?.state == e) {
        return;
      }
      emit(
        state.copyWith(
          models: {
            ...state.models,
            instance.id: inst!.copyWith(state: e),
          },
        ),
      );
    });
  }

  Future _syncModelConfig(
    String instanceId,
    DecodeParam param, [
    GenerationConfig? config,
  ]) async {
    ModelInstanceState instance = state.models[instanceId]!;
    bool updated = false;
    if (instance.config != config && config != null) {
      await instance.rwkv.setGenerationConfig(config);
      instance = instance.copyWith(config: config);
      updated = true;
    }
    if (instance.decodeParam != param) {
      await instance.rwkv.setDecodeParam(param);
      instance = instance.copyWith(decodeParam: param);
      updated = true;
    }
    if (updated) {
      emit(state.copyWith(models: {...state.models, instanceId: instance}));
    }
  }

  @override
  Future<ModelBaseInfo> getModelBaseInfo(String instanceId) async {
    final model = state.models[instanceId];
    if (model == null) return throw "Model not found, instanceId: $instanceId";
    return model.info;
  }

  @override
  Stream<ModelLoadState> onExternalRWKVLoaded(
    RWKV rwkv, {
    required ModelInfo info,
  }) async* {
    final instance = ModelInstanceState(
      rwkv: rwkv,
      id: info.id,
      info: ModelBaseInfo.fromModelInfo(info),
    );
    emit(state.copyWith(models: {...state.models, instance.id: instance}));
    yield ModelLoadState.loaded(
      info.id,
      info.name,
      instance.id,
      info.providerName,
    );
  }

  @override
  Future<void> close() async {
    await _remoteServiceSubscription.cancel();
    return super.close();
  }
}
