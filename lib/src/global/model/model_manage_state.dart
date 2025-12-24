part of 'model_manage_cubit.dart';

class ModelDownloadState {
  final TaskUpdate update;
  final dynamic error;

  ModelDownloadState({required this.update, required this.error});
}

class ModelManageState {
  final bool initialized;

  final List<ModelInfo> models;
  final List<ModelInfo> localModels;
  final Map<String, ModelDownloadState?> modelStates;
  final DownloadSource downloadSource;

  ModelManageState._({
    required this.initialized,
    required this.models,
    required this.localModels,
    required this.modelStates,
    required this.downloadSource,
  });

  factory ModelManageState.initial() {
    return ModelManageState._(
      initialized: false,
      models: [],
      modelStates: {},
      localModels: [],
      downloadSource: DownloadSource.aiFastHub,
    );
  }

  ModelManageState copyWith({
    bool? initialized,
    List<ModelInfo>? models,
    List<ModelInfo>? localModels,
    Map<String, ModelDownloadState?>? modelStates,
    DownloadSource? downloadSource,
  }) {
    return ModelManageState._(
      initialized: initialized ?? this.initialized,
      models: models ?? this.models,
      localModels: localModels ?? this.localModels,
      modelStates: modelStates ?? this.modelStates,
      downloadSource: downloadSource ?? this.downloadSource,
    );
  }
}
