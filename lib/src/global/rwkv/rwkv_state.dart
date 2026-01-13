part of 'rwkv_cubit.dart';

class ModelLoadState {
  final ModelInfo? model;
  final bool loading;
  final String error;

  ModelLoadState({
    required this.model,
    required this.loading,
    required this.error,
  });

  factory ModelLoadState.initial() {
    return ModelLoadState(model: null, loading: false, error: '');
  }
}

class ModelInstanceState {
  final String id;
  final RWKV rwkv;
  final ModelInfo info;
  final GenerationState state;
  final GenerationConfig config;
  final DecodeParam decodeParam;

  ModelInstanceState({
    required this.rwkv,
    required this.info,
    String? id,
    GenerationState? state,
    GenerationConfig? config,
    DecodeParam? decodeParam,
  }) : id = id ?? "${info.id}_${rwkv.hashCode}",
       decodeParam = decodeParam ?? DecodeParam.initial(),
       state = state ?? GenerationState.initial(),
       config = config ?? GenerationConfig.initial();

  ModelInstanceState copyWith({
    RWKV? rwkv,
    ModelInfo? info,
    GenerationState? state,
    GenerationConfig? config,
    DecodeParam? decodeParam,
  }) {
    return ModelInstanceState(
      rwkv: rwkv ?? this.rwkv,
      info: info ?? this.info,
      state: state ?? this.state,
      config: config ?? this.config,
      decodeParam: decodeParam ?? this.decodeParam,
    );
  }
}

class RwkvState {
  final Map<String, ModelInstanceState> models;
  final ModelLoadState modelLoadState;

  RwkvState({required this.models, required this.modelLoadState});

  factory RwkvState.initial() {
    return RwkvState(models: {}, modelLoadState: ModelLoadState.initial());
  }

  RwkvState copyWith({
    Map<String, ModelInstanceState>? models,
    ModelLoadState? modelLoadState,
  }) {
    return RwkvState(
      models: models ?? this.models,
      modelLoadState: modelLoadState ?? this.modelLoadState,
    );
  }
}
