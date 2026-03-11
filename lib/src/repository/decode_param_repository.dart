import 'dart:convert';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/cache/state_cache_box.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';

class DecodeParamRepository {
  const DecodeParamRepository();

  Future<Map<String, DecodeParam>> getAll() async {
    final states = await StateCacheBox.getAll(
      nameSpace: StateCacheBox.nsSpaceDecodeParam,
    );
    return states
        .where((e) => e.key.isNotEmpty)
        .associate(
          (e) => e.key,
          (e) => DecodeParam.fromMap(
            Map<String, dynamic>.from(jsonDecode(e.value)),
          ),
        );
  }

  Future<void> put(String id, DecodeParam param) async {
    await StateCacheBox.put(
      id,
      param.toMap(),
      nameSpace: StateCacheBox.nsSpaceDecodeParam,
    );
  }

  Future<void> delete(String id) async {
    await StateCacheBox.delete(id, nameSpace: StateCacheBox.nsSpaceDecodeParam);
  }
}
