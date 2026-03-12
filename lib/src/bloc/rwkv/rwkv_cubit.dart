import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart' hide ModelBaseInfo;
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_state.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/repository/decode_param_repository.dart';
import 'package:rwkv_studio/src/repository/llm_session_repository.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

export 'model_load_state.dart';
export 'rwkv_state.dart';

extension Ext on BuildContext {
  RwkvCubit get rwkv => BlocProvider.of<RwkvCubit>(this);

  RwkvState get rwkvState => rwkv.state;
}

class RwkvCubit extends Cubit<RwkvState> with RwkvInterface {
  final DecodeParamRepository _decodeParamRepository;
  final LlmSessionRepository _llmSessionRepository;
  late final StreamSubscription<LlmSessionSnapshot> _sessionSubscription;

  RwkvCubit(this._decodeParamRepository, this._llmSessionRepository)
    : super(RwkvState.initial()) {
    _sessionSubscription = _llmSessionRepository.watchSnapshot().listen((
      snapshot,
    ) {
      emit(state.copyWith(models: snapshot.models));
    });
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
        models: _llmSessionRepository.models,
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

  ModelInstanceState? getModelInstance(String? modelInstanceId) {
    return state.models[modelInstanceId];
  }

  @override
  Future<List<String>> getLoadedInstance(String modelId) {
    return _llmSessionRepository.getLoadedInstance(modelId);
  }

  @override
  Future stop(String instanceId) {
    return _llmSessionRepository.stop(instanceId);
  }

  Future<void> setDecodeParam(String modelInstanceId, DecodeParam param) {
    return _llmSessionRepository.setDecodeParam(modelInstanceId, param);
  }

  @override
  Stream<GenerationResponse> chat(
    List<ChatMessage> message,
    String instanceId,
    String decodeParamId,
    GenerationConfig config,
  ) async* {
    final decodeParam = _resolveDecodeParam(decodeParamId);
    logi(
      'chat: instance:$instanceId, decode:$decodeParamId, reasoning:${config.reasoningEffort}, prompt:${config.prompt}',
    );
    yield* _llmSessionRepository.chat(message, instanceId, decodeParam, config);
  }

  @override
  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    String decodeParamId, {
    int batch = 1,
    String? fimSuffix,
  }) async* {
    final decodeParam = _resolveDecodeParam(decodeParamId);
    yield* _llmSessionRepository.generate(
      prompt,
      instanceId,
      decodeParam,
      batch: batch,
      fimSuffix: fimSuffix,
    );
  }

  Future release(String modelInstanceId) {
    return _llmSessionRepository.release(modelInstanceId);
  }

  @override
  Stream<ModelLoadState> loadModel(
    ModelInfo modelInfo, {
    AlbatrossLaunchConfig? albatrossConfig,
  }) {
    return _llmSessionRepository.loadModel(
      modelInfo,
      albatrossConfig: albatrossConfig,
    );
  }

  @override
  Future<ModelBaseInfo> getModelBaseInfo(String instanceId) {
    return _llmSessionRepository.getModelBaseInfo(instanceId);
  }

  DecodeParam _resolveDecodeParam(String decodeParamId) {
    final param = decodeParamId.isEmpty
        ? DecodeParam.initial()
        : state.decodeParams[decodeParamId];
    if (param == null) {
      throw AppException('decode param not found $decodeParamId');
    }
    return param;
  }

  @override
  Future<void> close() async {
    await _sessionSubscription.cancel();
    return super.close();
  }
}
