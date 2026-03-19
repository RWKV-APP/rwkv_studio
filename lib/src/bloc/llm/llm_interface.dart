import 'package:fluent_ui/fluent_ui.dart';
import 'package:rwkv_dart/rwkv_dart.dart' hide ModelBaseInfo;
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/llm/model_load_state.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_state.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/chat/chat_event.dart';
import 'package:rwkv_studio/src/models/chat/message_model.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/models/model/remote_model_info.dart';
import 'package:rwkv_studio/src/repository/llm_session_repository.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

export 'model_load_state.dart';

mixin class LlmInterface {
  String roleAssistant = 'assistant';
  String roleUser = 'user';

  Future<ModelBaseInfo> getModelBaseInfo(String instanceId) async {
    throw const AppException.unimplemented(
      'getModelBaseInfo is not implemented',
    );
  }

  Future<List<String>> getLoadedInstance(String modelId) async {
    throw const AppException.unimplemented(
      'getLoadedInstance is not implemented',
    );
  }

  Future<void> stop(String instanceId) async {
    throw const AppException.unimplemented('stop is not implemented');
  }

  Stream<ModelLoadState> loadModel(
    ModelInfo modelInfo, {
    AlbatrossLaunchConfig? albatrossConfig,
  }) {
    throw const AppException.unimplemented('loadModel is not implemented');
  }

  Stream<ChatEvent> chat(
    List<MessageModel> message,
    String instanceId,
    String decodeParamId,
    GenerationConfig config,
  ) async* {
    throw const AppException.unimplemented('chat is not implemented');
  }

  Stream<GenerationResponse> generate(
    String prompt,
    String instanceId,
    String decodeParamId, {
    int batch = 1,
    String? fimSuffix,
  }) async* {
    throw const AppException.unimplemented('generate is not implemented');
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
      final info = await getModelBaseInfo(loaded.first);
      yield ModelLoadState.loaded(
        modelInfo.id,
        info.name,
        loaded.first,
        info.providerName,
      );
      return;
    }
    if (modelInfo.backend == ModelBackend.albatross && !modelInfo.isRemote) {
      if (!context.mounted) {
        yield ModelLoadState.error(
          modelInfo.id,
          const AppException.internal('Build context is not mounted'),
        );
        return;
      }
      try {
        final config = await _resolveAlbatrossLaunchConfig(context);
        yield* loadModel(modelInfo, albatrossConfig: config);
      } catch (e, s) {
        yield ModelLoadState.error(modelInfo.id, AppException.wrap(e, s));
      }
      return;
    }
    yield* loadModel(modelInfo);
  }

  Future<AlbatrossLaunchConfig> _resolveAlbatrossLaunchConfig(
    BuildContext context,
  ) async {
    final scriptPath = context.app.state.albatrossPath;
    if (scriptPath.isEmpty) {
      throw const AppException.configuration(
        'Albatross script path is not configured',
      );
    }

    final python = await context.app.getSelectedPython();
    if (python == null) {
      throw const AppException.configuration('No Python interpreter selected');
    }

    return AlbatrossLaunchConfig(python: python, scriptPath: scriptPath);
  }
}
