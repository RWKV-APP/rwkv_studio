part of 'model_manage_cubit.dart';

class ModelDownloadState {
  final TaskUpdate update;
  final dynamic error;

  ModelDownloadState({required this.update, required this.error});
}

class ModelManageState {
  final bool initialized;
  final bool runtimeReady;
  final bool runtimeLoading;
  final String runtimeError;

  final bool remoteModelRefreshed;
  final List<ModelInfo> models;
  final List<ModelInfo> remoteModels;
  final List<ModelInfo> importedModels;
  final List<ModelIdentity> disabledModelIds;
  final Map<String, ModelDownloadState?> modelStates;
  final DownloadSource downloadSource;
  final String downloadDir;
  final List<ModelTag> tags;
  final List<ModelGroup> groups;
  final List<ModelBackend> backends;

  List<ModelInfo> get allModels => [
    ...remoteModels,
    ...models,
    ...importedModels,
  ];

  Iterable<ModelInfo> get enabledRemoteModels =>
      remoteModels.where((e) => !disabledModelIds.contains(e.getIdentity()));

  List<ModelTag> getDisplayTags() {
    return tags.where((e) => e.name != 'mlx' && e.name != 'coreml').toList();
  }

  List<ModelGroup> getDisplayGroups() {
    return groups
        .where((e) => e.name != 'sudoku' && e.name != 'othello')
        .toList();
  }

  bool shouldModelListUpdate(ModelManageState other) {
    return other.models != models ||
        other.importedModels != importedModels ||
        remoteModels != other.remoteModels;
  }

  ModelManageState._({
    required this.initialized,
    required this.runtimeReady,
    required this.runtimeLoading,
    required this.runtimeError,
    required this.models,
    required this.modelStates,
    required this.downloadSource,
    required this.downloadDir,
    required this.tags,
    required this.groups,
    required this.backends,
    required this.importedModels,
    required this.remoteModels,
    required this.disabledModelIds,
    required this.remoteModelRefreshed,
  });

  factory ModelManageState.initial() {
    return ModelManageState._(
      initialized: false,
      runtimeReady: false,
      runtimeLoading: false,
      remoteModelRefreshed: false,
      runtimeError: '',
      models: [],
      modelStates: {},
      downloadSource: DownloadSource.aiFastHub,
      downloadDir: '',
      tags: [],
      groups: const [],
      backends: [],
      importedModels: [],
      remoteModels: [],
      disabledModelIds: [],
    );
  }

  ModelManageState copyWith({
    bool? initialized,
    bool? runtimeReady,
    bool? runtimeLoading,
    String? runtimeError,
    List<ModelInfo>? models,
    List<ModelInfo>? localModels,
    Map<String, ModelDownloadState?>? modelStates,
    DownloadSource? downloadSource,
    String? downloadDir,
    List<ModelTag>? tags,
    List<ModelGroup>? groups,
    List<ModelBackend>? backends,
    List<ModelInfo>? importedModels,
    List<ModelInfo>? remoteModels,
    List<ModelIdentity>? disabledModelIds,
    bool? remoteModelRefreshed,
  }) {
    return ModelManageState._(
      initialized: initialized ?? this.initialized,
      runtimeReady: runtimeReady ?? this.runtimeReady,
      runtimeLoading: runtimeLoading ?? this.runtimeLoading,
      runtimeError: runtimeError ?? this.runtimeError,
      models: models ?? this.models,
      modelStates: modelStates ?? this.modelStates,
      downloadSource: downloadSource ?? this.downloadSource,
      downloadDir: downloadDir ?? this.downloadDir,
      tags: tags ?? this.tags,
      groups: groups ?? this.groups,
      backends: backends ?? this.backends,
      importedModels: importedModels ?? this.importedModels,
      remoteModels: remoteModels ?? this.remoteModels,
      disabledModelIds: disabledModelIds ?? this.disabledModelIds,
      remoteModelRefreshed: remoteModelRefreshed ?? this.remoteModelRefreshed,
    );
  }
}
