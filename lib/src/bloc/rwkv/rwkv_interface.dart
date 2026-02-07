import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/python/albatross.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'model_load_state.dart';

/// Interface for abstract RWKV
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

  Stream<ModelLoadState> onExternalRWKVLoaded(RWKV rwkv, ModelInfo modelInfo) {
    throw UnimplementedError();
  }

  Stream<GenerationResponse> chat(
    List<String> message,
    String instanceId,
    String decodeParamId,
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

  Stream<ModelLoadState> loadOrGetModelInstance(
    BuildContext context,
    ModelInfo modelInfo,
  ) async* {
    final loaded = await getLoadedInstance(modelInfo.id);
    logi(
      'load or get model instance: ${modelInfo.id}, loaded: ${loaded.length}',
    );
    if (loaded.isNotEmpty) {
      final name = await getModelName(loaded.first);
      yield ModelLoadState.loaded(modelInfo.id, name, loaded.first);
      return;
    }
    if (modelInfo.backend == ModelBackend.albatross) {
      if (!context.mounted) {
        yield ModelLoadState.error(modelInfo.id, 'context not mounted');
        return;
      }
      try {
        yield ModelLoadState.loading(modelInfo.id);
        final r = await _loadAlbatross(context, modelInfo);
        yield* onExternalRWKVLoaded(r, modelInfo);
      } catch (e) {
        yield ModelLoadState.error(modelInfo.id, e);
      }
      return;
    }
    yield* loadModel(modelInfo);
  }

  Future<RWKV> _loadAlbatross(BuildContext context, ModelInfo model) async {
    final python = context.app.getSelectedPython();
    if (python == null) {
      throw 'no python interpreter selected';
    }

    final scriptPath = context.app.state.albatrossPath;
    if (scriptPath.isEmpty) {
      throw 'albatross script path not found';
    }

    final cmd = AlbatrossLauncher(
      python: python,
      scriptPath: scriptPath,
      modelPath: model.localPath,
    );
    return cmd.startup();
  }
}
