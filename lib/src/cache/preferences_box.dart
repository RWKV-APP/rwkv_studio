import 'package:hive_ce/hive_ce.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';

import 'hive_manager.dart';

part 'preferences_box.g.dart';

@HiveType(typeId: 1)
class PreferencesBox {
  @HiveField(0)
  Map<String, dynamic> model;

  @HiveField(1)
  Map<String, dynamic> appearance;

  @HiveField(2)
  Map<String, dynamic> python;

  @HiveField(3)
  Map<String, dynamic> cache;

  /// flatten all settings to one object
  PreferencesBox({
    required this.model,
    required this.appearance,
    required this.python,
    required this.cache,
  });

  static Future putRaw(AppSettingsModel value) {
    return HiveManager.preferencesBox.put(
      'default',
      PreferencesBox.fromSettings(value),
    );
  }

  static Future<AppSettingsModel?> getRaw() async {
    final v = HiveManager.preferencesBox.get('default');
    return v?.toSettings();
  }

  factory PreferencesBox.fromSettings(AppSettingsModel settings) {
    return PreferencesBox(
      model: settings.model.toMap(),
      appearance: settings.appearance.toMap(),
      python: settings.python.toMap(),
      cache: settings.cache.toMap(),
    );
  }

  AppSettingsModel toSettings() {
    return AppSettingsModel(
      model: ModelSettingsModel.fromMap(model),
      appearance: AppearanceSettingsModel.fromMap(appearance),
      python: PythonSettingsModel.fromMap(python),
      cache: CacheSettingsModel.fromMap(cache),
    );
  }
}
