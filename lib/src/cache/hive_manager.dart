import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:rwkv_studio/src/cache/state_cache_box.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

import 'conversation_box.dart';
import 'message_box.dart';
import 'model_file_box.dart';
import 'preferences_box.dart';

class HiveManager {
  HiveManager._();

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    if (!kIsWeb) {
      final appDir = appDataDir;
      final hiveDir = Directory('${appDir.path}${Platform.pathSeparator}hive');
      if (!await hiveDir.exists()) {
        await hiveDir.create(recursive: true);
      }
      await Hive.initFlutter(hiveDir.path);
    } else {
      Hive.init('hive');
    }

    Hive.registerAdapter(PreferencesBoxAdapter());
    Hive.registerAdapter(ConversationBoxAdapter());
    Hive.registerAdapter(MessageBoxAdapter());
    Hive.registerAdapter(ModelFileBoxAdapter());
    Hive.registerAdapter(StateCacheBoxAdapter());
    logd('hive initialized');
  }

  /// Close all boxes
  static Future<void> close() async {
    await Hive.close();
  }

  /// Clear all data
  static Future<void> clear() async {
    await PreferencesBox.clear();
    await ConversationBox.clear();
    await ModelFileBox.clear();
  }
}
