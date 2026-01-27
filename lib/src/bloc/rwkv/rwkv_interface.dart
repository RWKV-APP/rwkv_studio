import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'model_load_state.dart';

mixin class RwkvInterface {
  String roleAssistant = 'assistant';
  String roleUser = 'user';

  Future<String> getModelName(String instanceId) async {
    throw UnimplementedError();
  }

  Future<List<String>> getLoadedInstance(String modelId) async {
    throw UnimplementedError();
  }

  Future<void> stop(String instanceId) async {
    throw UnimplementedError();
  }

  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) {
    throw UnimplementedError();
  }

  Stream<GenerationResponse> chat(
    List<String> message,
    String instanceId,
    DecodeParam param,
    GenerationConfig config,
  ) async* {
    throw UnimplementedError();
  }

  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    DecodeParam decodeParam,
  ) async* {
    throw UnimplementedError();
  }

  Stream<ModelLoadState> loadOrGetModelInstance(ModelInfo modelInfo) async* {
    final loaded = await getLoadedInstance(modelInfo.id);
    logi(
      'load or get model instance: ${modelInfo.id}, loaded: ${loaded.length}',
    );
    if (loaded.isNotEmpty) {
      final name = await getModelName(loaded.first);
      yield ModelLoadState.loaded(modelInfo.id, name, loaded.first);
      return;
    }
    yield* loadModel(modelInfo);
  }
}
