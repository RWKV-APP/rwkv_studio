import 'package:rwkv_dart/rwkv_dart.dart' hide ModelBaseInfo;
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_state.dart';
import 'package:rwkv_studio/src/bloc/llm/model_load_state.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/chat/chat_event.dart';
import 'package:rwkv_studio/src/models/chat/message_model.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';

export 'model_load_state.dart';

/// [LlmInterface] General interface of LLMs for UI purposes
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

  Stream<ModelLoadState> loadModel(ModelInfo modelInfo) {
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
    List<int>? stopTokenIds,
  }) async* {
    throw const AppException.unimplemented('generate is not implemented');
  }
}
