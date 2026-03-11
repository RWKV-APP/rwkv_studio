import 'package:rwkv_dart/rwkv_dart.dart';

class DecodeParamRepository {
  const DecodeParamRepository();

  Future<Map<String, DecodeParam>> getAll() async {
    return {'default': DecodeParam.initial()};
  }

  Future<void> put(String id, DecodeParam param) async {}

  Future<void> delete(String id) async {}
}
