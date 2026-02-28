part of 'model_manage_cubit.dart';

class ModelDownloadState {
  final TaskUpdate update;
  final dynamic error;

  ModelDownloadState({required this.update, required this.error});
}

class ModelManageState {
  final bool initialized;

  final List<ModelInfo> models;
  final List<ModelInfo> remoteModels;
  final List<ModelInfo> importedModels;
  final Map<String, ModelDownloadState?> modelStates;
  final DownloadSource downloadSource;
  final String downloadDir;
  final List<ModelTag> tags;
  final List<ModelGroup> groups;
  final List<ModelBackend> backends;
  final List<ModelListProvider> remoteModelProviders;

  List<ModelInfo> get allModels => [
    ...remoteModels,
    ...models,
    ...importedModels,
  ];

  List<ModelTag> getDisplayTags() {
    return tags.where((e) => e.name != 'mlx' && e.name != 'coreml').toList();
  }

  List<ModelGroup> getDisplayGroups() {
    return groups
        .where((e) => e.name != 'sudoku' && e.name != 'othello')
        .toList();
  }

  bool shouldModelListUpdate(ModelManageState other) {
    return other.models.length != models.length ||
        other.importedModels.length != importedModels.length ||
        remoteModels.length != other.remoteModels.length;
  }

  ModelManageState._({
    required this.initialized,
    required this.models,
    required this.modelStates,
    required this.downloadSource,
    required this.downloadDir,
    required this.tags,
    required this.groups,
    required this.backends,
    required this.remoteModelProviders,
    required this.importedModels,
    required this.remoteModels,
  });

  factory ModelManageState.initial() {
    return ModelManageState._(
      initialized: false,
      models: [],
      modelStates: {},
      downloadSource: DownloadSource.aiFastHub,
      downloadDir: '',
      tags: [],
      groups: const [],
      backends: [],
      remoteModelProviders: [],
      importedModels: [],
      remoteModels: [],
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
    List<ModelListProvider>? remoteModelProviders,
    List<ModelInfo>? importedModels,
    List<ModelInfo>? remoteModels,
  }) {
    return ModelManageState._(
      initialized: initialized ?? this.initialized,
      models: models ?? this.models,
      modelStates: modelStates ?? this.modelStates,
      downloadSource: downloadSource ?? this.downloadSource,
      downloadDir: downloadDir ?? this.downloadDir,
      tags: tags ?? this.tags,
      groups: groups ?? this.groups,
      backends: backends ?? this.backends,
      remoteModelProviders: remoteModelProviders ?? this.remoteModelProviders,
      importedModels: importedModels ?? this.importedModels,
      remoteModels: remoteModels ?? this.remoteModels,
    );
  }
}
