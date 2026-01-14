import 'package:rwkv_dart/rwkv_dart.dart';

abstract class RwkvInterface {
  String getModelName(String instanceId) {
    return 'rwkv';
  }

  Future<void> stop(String instanceId) async {
    //
  }

  Stream<String> chat(
    List<String> message,
    String instanceId,
    DecodeParam param,
    int maxTokens,
  ) async* {
    //
  }

  Stream<String> generate(
    String prompt,
    String instanceId,
    DecodeParam decodeParam,
    int maxTokens,
  ) async* {
    //
  }
}
