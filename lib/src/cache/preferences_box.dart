import 'package:hive_ce/hive_ce.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';

part 'preferences_box.g.dart';

@HiveType(typeId: 1)
class PreferencesBox {
  static const _boxName = 'preferences';
  static Box<PreferencesBox>? _box;
  static Future<Box<PreferencesBox>>? _openingBox;

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

  static Future<Box<PreferencesBox>> _instance() async {
    final box = _box;
    if (box != null) {
      if (box.isOpen) {
        return box;
      }
      _box = null;
      _openingBox = null;
    }

    final openingBox = _openingBox;
    if (openingBox != null) {
      return openingBox;
    }

    final future = Hive.openBox<PreferencesBox>(_boxName);
    _openingBox = future;
    try {
      final openedBox = await future;
      _box = openedBox;
      return openedBox;
    } catch (_) {
      _openingBox = null;
      rethrow;
    }
  }

  static Future<void> putRaw(AppSettingsModel value) async {
    final box = await _instance();
    await box.put(
      'default',
      PreferencesBox.fromSettings(value),
    );
  }

  static Future<AppSettingsModel?> getRaw() async {
    final box = await _instance();
    final v = box.get('default');
    return v?.toSettings();
  }

  static Future<void> clear() async {
    final box = await _instance();
    await box.clear();
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
