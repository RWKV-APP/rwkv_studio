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

  static Box<PreferencesBox>? _preferencesBox;
  static Box<ConversationBox>? _conversationBox;
  static Box<ModelFileBox>? _modelFileBox;

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    if (!kIsWeb) {
      final appDir = appExecutableDir;
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

  /// Get preferences box
  static Box<PreferencesBox> get preferencesBox {
    return _preferencesBox!;
  }

  /// Open preferences box
  static Future<Box<PreferencesBox>> openPreferencesBox() async {
    _preferencesBox ??= await Hive.openBox<PreferencesBox>('preferences');
    return _preferencesBox!;
  }

  /// Get conversation box
  static Box<ConversationBox> get conversationBox {
    assert(
      _conversationBox != null,
      'Conversation box not opened. Call openConversationBox() first.',
    );
    return _conversationBox!;
  }

  /// Open conversation box
  static Future<Box<ConversationBox>> openConversationBox() async {
    _conversationBox ??= await Hive.openBox<ConversationBox>('conversations');
    return _conversationBox!;
  }

  /// Get model file box
  static Box<ModelFileBox> get modelFileBox {
    assert(
      _modelFileBox != null,
      'Model file box not opened. Call openModelFileBox() first.',
    );
    return _modelFileBox!;
  }

  /// Open model file box
  static Future<Box<ModelFileBox>> openModelFileBox() async {
    _modelFileBox ??= await Hive.openBox<ModelFileBox>('model_files');
    return _modelFileBox!;
  }

  /// Close all boxes
  static Future<void> close() async {
    await _preferencesBox?.close();
    await _conversationBox?.close();
    await _modelFileBox?.close();
    _preferencesBox = null;
    _conversationBox = null;
    _modelFileBox = null;
  }

  /// Clear all data
  static Future<void> clear() async {
    await _preferencesBox?.clear();
    await _conversationBox?.clear();
    await _modelFileBox?.clear();
  }
}
