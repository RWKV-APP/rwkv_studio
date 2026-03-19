class ModelLoadState {
  final String modelId;
  final String modelName;
  final String providerName;
  final String instanceId;
  final bool loading;
  final String error;

  bool get succeed => !loading && error.isEmpty && instanceId.isEmpty;

  bool get isRWKV => modelName.toLowerCase().contains('rwkv');

  String get displayName =>
      [providerName, modelName].where((e) => e.isNotEmpty).join(': ').trim();

  ModelLoadState({
    required this.providerName,
    required this.modelId,
    required this.modelName,
    required this.loading,
    required this.error,
    required this.instanceId,
  });

  factory ModelLoadState.loading(String modelId) {
    return ModelLoadState(
      modelId: modelId,
      modelName: modelId,
      loading: true,
      error: '',
      instanceId: '',
      providerName: '',
    );
  }

  factory ModelLoadState.loaded(
    String modelId,
    String name,
    String instanceId,
    String providerName,
  ) {
    return ModelLoadState(
      modelId: modelId,
      modelName: name,
      loading: false,
      error: '',
      instanceId: instanceId,
      providerName: providerName,
    );
  }

  factory ModelLoadState.error(String modelId, dynamic error) {
    return ModelLoadState(
      modelId: modelId,
      loading: false,
      modelName: modelId,
      error: error.toString(),
      instanceId: '',
      providerName: '',
    );
  }

  factory ModelLoadState.empty() {
    return ModelLoadState(
      modelId: '',
      loading: false,
      modelName: '',
      error: '',
      instanceId: '',
      providerName: '',
    );
  }
}
