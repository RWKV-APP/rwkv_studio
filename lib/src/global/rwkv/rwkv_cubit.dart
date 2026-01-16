import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/rwkv/rwkv.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'rwkv_state.dart';

extension Ext on BuildContext {
  RwkvCubit get rwkv => BlocProvider.of<RwkvCubit>(this);

  RwkvState get rwkvState => rwkv.state;
}

class RwkvCubit extends Cubit<RwkvState> implements RwkvInterface {
  RwkvCubit() : super(RwkvState.initial());

  void init() async {
    //
  }

  void clearLoadState() {
    emit(state.copyWith(modelLoadState: ModelLoadState.initial()));
  }

  ModelInstanceState? getModelInstance(String? modelInstanceId) {
    return state.models[modelInstanceId];
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
    DecodeParam param,
  ) async* {
    final instance = state.models[instanceId];
    if (instance == null) throw "Model not found";
    await _syncModelConfig(instanceId, param);
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

  Future<ModelInstanceState> loadModel(ModelInfo model) async {
    final rwkv = kIsWeb ? RWKV.create() : RWKV.isolated();
    await rwkv.init(InitParam(logLevel: RWKVLogLevel.verbose));
    emit(
      state.copyWith(
        modelLoadState: ModelLoadState(model: model, loading: true, error: ''),
      ),
    );
    try {
      await rwkv.loadModel(
        LoadModelParam(
          modelPath: model.localPath,
          tokenizerPath: AppAssets.rwkvVocab20230424,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          modelLoadState: ModelLoadState(
            model: model,
            loading: false,
            error: e.toString(),
          ),
        ),
      );
      rethrow;
    }
    final instance = ModelInstanceState(rwkv: rwkv, info: model);
    emit(
      state.copyWith(
        models: {...state.models, instance.id: instance},
        modelLoadState: ModelLoadState.initial(),
      ),
    );

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

    return instance;
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
  String getModelName(String instanceId) {
    return state.models[instanceId]!.info.name;
  }
}
