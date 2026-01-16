import 'package:rwkv_dart/rwkv_dart.dart';

abstract class RwkvInterface {
  String getModelName(String instanceId) {
    return 'rwkv';
  }

  Future<void> stop(String instanceId) async {
    //
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
}
