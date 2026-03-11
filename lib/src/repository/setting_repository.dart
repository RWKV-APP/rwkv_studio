import 'package:rwkv_studio/src/models/settings/settings_models.dart';

class SettingRepository {
  const SettingRepository();

  Future<AppSettingsModel?> load() async {
    return null;
  }

  Future<void> save(AppSettingsModel settings) async {}

  Future<AppSettingsModel> reset() async {
    return AppSettingsModel.initial();
  }

  Future<CacheSettingsModel> validateCacheSetting(
    CacheSettingsModel cache, {
    CacheSettingsModel? fallback,
  }) async {
    return cache;
  }
}
