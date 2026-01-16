part of 'rwkv_interface.dart';

class ModelLoadState {
  final String modelId;
  final String displayName;
  final String instanceId;
  final bool loading;
  final String error;

  ModelLoadState({
    required this.modelId,
    required this.displayName,
    required this.loading,
    required this.error,
    required this.instanceId,
  });

  factory ModelLoadState.loading(String modelId) {
    return ModelLoadState(
      modelId: modelId,
      displayName: modelId,
      loading: true,
      error: '',
      instanceId: '',
    );
  }

  factory ModelLoadState.loaded(
    String modelId,
    String displayName,
    String instanceId,
  ) {
    return ModelLoadState(
      modelId: modelId,
      displayName: displayName,
      loading: false,
      error: '',
      instanceId: instanceId,
    );
  }

  factory ModelLoadState.error(String modelId, dynamic error) {
    return ModelLoadState(
      modelId: modelId,
      loading: false,
      displayName: modelId,
      error: error.toString(),
      instanceId: '',
    );
  }

  factory ModelLoadState.empty() {
    return ModelLoadState(
      modelId: '',
      loading: false,
      displayName: '',
      error: '',
      instanceId: '',
    );
  }
}
