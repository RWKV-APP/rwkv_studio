import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'rwkv_state.dart';

extension Ext on BuildContext {
  RwkvCubit get rwkv => BlocProvider.of<RwkvCubit>(this);

  RwkvState get rwkvState => rwkv.state;
}

class RwkvCubit extends Cubit<RwkvState> with RwkvInterface {
  RwkvCubit() : super(RwkvState.initial());

  void init() async {
    //
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
    final instance = state.models[instanceId]!;
    await instance.rwkv.stopGenerate();
  }

  Future setDecodeParam(String modelInstanceId, DecodeParam param) async {
    final instance = state.models[modelInstanceId]!;
    await instance.rwkv.setDecodeParam(param);
  }

  @override
  Stream<GenerationResponse> chat(
    List<String> message,
    String instanceId,
    DecodeParam param,
  ) async* {
    final instance = state.models[instanceId];
    if (instance == null) throw "Model not found";
    await _syncModelConfig(instanceId, param);
    try {
      yield* instance.rwkv.chat(message);
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
    DecodeParam decodeParam,
  ) async* {
    final instance = state.models[instanceId];
    if (instance == null) throw "Model not found";
    await _syncModelConfig(instanceId, decodeParam);
    await instance.rwkv.clearState();
    try {
      yield* instance.rwkv.generate(prompt);
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
    emit(state.copyWith(models: {...state.models}..remove(modelInstanceId)));
  }

  @override
  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) async* {
    final rwkv = kIsWeb ? RWKV.create() : RWKV.isolated();
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
    final instance = ModelInstanceState(rwkv: rwkv, info: modelInfo);
    emit(state.copyWith(models: {...state.models, instance.id: instance}));
    yield ModelLoadState.loaded(modelInfo.id, modelInfo.name, instance.id);
    rwkv.generationStateStream().listen((e) {
      final inst = state.models[instance.id];
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

  Future _syncModelConfig(String instanceId, DecodeParam param) async {
    final instance = state.models[instanceId]!;
    if (instance.decodeParam != param) {
      await instance.rwkv.setDecodeParam(param);
      emit(
        state.copyWith(
          models: {
            ...state.models,
            instanceId: instance.copyWith(decodeParam: param),
          },
        ),
      );
    }
  }

  @override
  Future<String> getModelName(String instanceId) async {
    final model = state.models[instanceId];
    if (model == null) return throw "Model not found";
    return model.info.name;
  }
}
