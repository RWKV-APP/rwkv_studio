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
  final String downloadDir;
  final List<ModelTag> tags;
  final List<ModelGroup> groups;
  final List<ModelBackend> backends;

  ModelManageState._({
    required this.initialized,
    required this.models,
    required this.localModels,
    required this.modelStates,
    required this.downloadSource,
    required this.downloadDir,
    required this.tags,
    required this.groups,
    required this.backends,
  });

  factory ModelManageState.initial() {
    return ModelManageState._(
      initialized: false,
      models: [],
      modelStates: {},
      localModels: [],
      downloadSource: DownloadSource.aiFastHub,
      downloadDir: '',
      tags: [],
      groups: const [],
      backends: [],
    );
  }

  ModelManageState copyWith({
    bool? initialized,
    List<ModelInfo>? models,
    List<ModelInfo>? localModels,
    Map<String, ModelDownloadState?>? modelStates,
    DownloadSource? downloadSource,
    String? downloadDir,
    List<ModelTag>? tags,
    List<ModelGroup>? groups,
    List<ModelBackend>? backends,
  }) {
    return ModelManageState._(
      initialized: initialized ?? this.initialized,
      models: models ?? this.models,
      localModels: localModels ?? this.localModels,
      modelStates: modelStates ?? this.modelStates,
      downloadSource: downloadSource ?? this.downloadSource,
      downloadDir: downloadDir ?? this.downloadDir,
      tags: tags ?? this.tags,
      groups: groups ?? this.groups,
      backends: backends ?? this.backends,
    );
  }
}
