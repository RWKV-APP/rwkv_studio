import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class InitConfig {
  final bool isDark;

  static InitConfig _instance = InitConfig._();

  static InitConfig get instance => _instance;

  InitConfig._({this.isDark = false});

  static Future<InitConfig> load() async {
    if (kIsWeb) {
      return _instance;
    }

    final dir = await getApplicationCacheDirectory();
    final file = dir
        .childDirectory('rwkv_studio')
        .childFile('init_config.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final map = jsonDecode(content);
        _instance = InitConfig.fromMap(map);
      } catch (e, s) {
        loge("load init config error", e, s);
      }
    }
    return _instance;
  }

  static Future update({bool? isDark}) async {
    if (kIsWeb) {
      return;
    }
    if (isDark == _instance.isDark) {
      return;
    }

    _instance = InitConfig._(isDark: isDark ?? _instance.isDark);
    final dir = await getApplicationCacheDirectory();
    final file = dir
        .childDirectory('rwkv_studio')
        .childFile('init_config.json');
    if (!file.existsSync()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(_instance.toMap()));
  }

  Map<String, dynamic> toMap() {
    return {'is_dark': isDark};
  }

  factory InitConfig.fromMap(Map<String, dynamic> map) {
    return InitConfig._(isDark: map['is_dark'] as bool);
  }
}
