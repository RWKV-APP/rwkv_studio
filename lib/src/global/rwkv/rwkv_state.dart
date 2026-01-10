part of 'rwkv_cubit.dart';

class ModelLoadState {
  final ModelInfo? model;
  final bool loading;
  final dynamic error;

  ModelLoadState({
    required this.model,
    required this.loading,
    required this.error,
  });

  factory ModelLoadState.initial() {
    return ModelLoadState(model: null, loading: false, error: null);
  }
}

class ModelInstanceState {
  final String id;
  final RWKV rwkv;
  final ModelInfo info;
  GenerationState state;

  ModelInstanceState({
    required this.rwkv,
    required this.info,
    String? id,
    GenerationState? state,
  }) : id = id ?? "${info.id}_${rwkv.hashCode}",
       state = state ?? GenerationState.initial();

  ModelInstanceState copyWith({
    RWKV? rwkv,
    ModelInfo? info,
    GenerationState? state,
  }) {
    return ModelInstanceState(
      rwkv: rwkv ?? this.rwkv,
      info: info ?? this.info,
      state: state ?? this.state,
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
