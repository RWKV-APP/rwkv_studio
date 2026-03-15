import 'dart:convert';

import 'package:hive_ce/hive.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'state_cache_box.g.dart';

@HiveType(typeId: 6)
class StateCacheBox {
  static const String nsSpaceDecodeParam = 'ns_decode_param';

  @HiveField(0)
  String key;

  @HiveField(1)
  String value;

  @HiveField(2)
  String type;

  @HiveField(3)
  int updateAt;

  @HiveField(4)
  String nameSpace;

  StateCacheBox({
    required this.key,
    required this.value,
    required this.updateAt,
    required this.type,
    this.nameSpace = '',
  });

  static Box<StateCacheBox>? _stateCacheBox;

  static Future<Box<StateCacheBox>> _instance() async {
    try {
      _stateCacheBox ??= await Hive.openBox<StateCacheBox>('state_cache');
    } catch (e, s) {
      final error = AppException.storage(
        'Failed to open state cache box',
        cause: e,
        stackTrace: s,
      );
      loge(error, s);
      Error.throwWithStackTrace(error, s);
    }
    return _stateCacheBox!;
  }

  static Future<StateCacheBox?> get(String key, {String? nameSpace}) async {
    final box = await _instance();
    if (nameSpace != null) {
      key = '${nameSpace}_$key';
    }
    final v = box.get(key);
    return v;
  }

  static Future delete(String key, {String? nameSpace}) async {
    final box = await _instance();
    if (nameSpace != null) {
      key = '${nameSpace}_$key';
    }
    await box.delete(key);
  }

  static Future<List<StateCacheBox>> getAll({String? nameSpace}) async {
    final box = await _instance();
    if (nameSpace == null || nameSpace.isEmpty) {
      return box.values.toList();
    }
    return box.values.where((v) => v.nameSpace == nameSpace).toList();
  }

  static Future<void> put(
    String key,
    dynamic value, {
    String? nameSpace,
  }) async {
    final box = await _instance();

    String type;
    if (value is Map) {
      type = 'map';
      value = jsonEncode(value);
    } else if (value is List) {
      type = 'list';
      value = jsonEncode(value);
    } else if (value is String) {
      type = 'string';
    } else if (value is int) {
      type = 'int';
    } else if (value is double) {
      type = 'double';
    } else if (value is bool) {
      type = 'bool';
    } else {
      type = 'unknown';
    }

    String realKey = key;
    if (nameSpace != null) {
      realKey = '${nameSpace}_$key';
    }

    await box.put(
      realKey,
      StateCacheBox(
        key: key,
        value: value.toString(),
        type: type,
        nameSpace: nameSpace ?? '',
        updateAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}
