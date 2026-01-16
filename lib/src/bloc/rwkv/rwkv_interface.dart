import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';

part 'model_load_state.dart';

mixin class RwkvInterface {
  Future<String> getModelName(String instanceId) async {
    return '';
  }

  Future<List<String>> getLoadedInstance(String modelId) async {
    return [];
  }

  Future<void> stop(String instanceId) async {
    //
  }

  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) {
    return Stream.empty();
  }

  Stream<GenerationResponse> chat(
    List<String> message,
    String instanceId,
    DecodeParam param,
  ) async* {
    //
  }

  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    DecodeParam decodeParam,
  ) async* {
    //
  }

  Stream<ModelLoadState> loadOrGetModelInstance(ModelInfo modelInfo) async* {
    final loaded = await getLoadedInstance(modelInfo.id);
    if (loaded.isNotEmpty) {
      final name = await getModelName(loaded.first);
      yield ModelLoadState.loaded(modelInfo.id, name, loaded.first);
      return;
    }
    yield* loadModel(modelInfo);
  }
}
