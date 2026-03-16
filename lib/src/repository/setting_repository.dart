import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rwkv_studio/src/cache/setting_box.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class SettingRepository {
  const SettingRepository();

  Future<AppSettingsModel?> load() async {
    final settings = await SettingBox.getRaw();
    if (settings == null) {
      return null;
    }
    return _normalize(
      settings.copyWith(cache: await validateCacheSetting(settings.cache)),
    );
  }

  Future<void> save(AppSettingsModel settings) async {
    await SettingBox.putRaw(settings);
  }

  Future<AppSettingsModel> reset() async {
    final settings = _normalize(
      AppSettingsModel.initial().copyWith(
        cache: await validateCacheSetting(CacheSettingsModel.initial()),
      ),
    );
    await save(settings);
    return settings;
  }

  Future<CacheSettingsModel> validateCacheSetting(
    CacheSettingsModel cache, {
    CacheSettingsModel? fallback,
  }) async {
    if (kIsWeb) {
      return cache;
    }
    final reset = fallback ?? CacheSettingsModel.initial();
    final modelDownloadDir = await _ensureDirectory(
      cache.modelDownloadDir,
      fallback: reset.modelDownloadDir,
      label: 'model dir',
    );
    final appCacheDir = await _ensureDirectory(
      cache.appCacheDir,
      fallback: reset.appCacheDir,
      label: 'cache dir',
    );
    return cache.copyWith(
      modelDownloadDir: modelDownloadDir,
      appCacheDir: appCacheDir,
    );
  }

  Future<String> _ensureDirectory(
    String path, {
    required String fallback,
    required String label,
  }) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    } catch (e, s) {
      final error = AppException.wrap(e, s);
      loge('$label is not available', error, error.stackTrace ?? s);
      logw('$label is not available, reset to $fallback');
      return fallback;
    }
  }

  AppSettingsModel _normalize(AppSettingsModel settings) {
    final model = settings.model;
    final normalizedModel = model.copyWith(
      modelListUrl: model.modelListUrl.isEmpty
          ? ModelSettingsModel.default_.modelListUrl
          : model.modelListUrl,
      enabledBackends: model.enabledBackends.isEmpty
          ? ModelSettingsModel.default_.enabledBackends
          : model.enabledBackends,
    );
    return settings.copyWith(model: normalizedModel);
  }
}
