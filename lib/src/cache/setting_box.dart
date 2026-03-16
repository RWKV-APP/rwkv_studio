import 'package:hive_ce/hive_ce.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';

part 'setting_box.g.dart';

@HiveType(typeId: 1)
class SettingBox {
  static const _boxName = 'setting';
  static Box<SettingBox>? _box;
  static Future<Box<SettingBox>>? _openingBox;

  @HiveField(0)
  Map<String, dynamic> model;

  @HiveField(1)
  Map<String, dynamic> appearance;

  @HiveField(2)
  Map<String, dynamic> python;

  @HiveField(3)
  Map<String, dynamic> cache;

  @HiveField(4)
  Map<String, dynamic> mcp;

  /// flatten all settings to one object
  SettingBox({
    required this.model,
    required this.appearance,
    required this.python,
    required this.cache,
    required this.mcp,
  });

  static Future<Box<SettingBox>> _instance() async {
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

    final future = Hive.openBox<SettingBox>(_boxName);
    _openingBox = future;
    try {
      final openedBox = await future;
      _box = openedBox;
      return openedBox;
    } catch (e, s) {
      _openingBox = null;
      Error.throwWithStackTrace(
        AppException.storage(
          'Failed to open preferences box',
          cause: e,
          stackTrace: s,
        ),
        s,
      );
    }
  }

  static Future<void> putRaw(AppSettingsModel value) async {
    final box = await _instance();
    await box.put('default', SettingBox.fromSettings(value));
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

  factory SettingBox.fromSettings(AppSettingsModel settings) {
    return SettingBox(
      model: settings.model.toMap(),
      appearance: settings.appearance.toMap(),
      python: settings.python.toMap(),
      cache: settings.cache.toMap(),
      mcp: settings.mcp.toMap(),
    );
  }

  AppSettingsModel toSettings() {
    return AppSettingsModel(
      model: ModelSettingsModel.fromMap(model),
      appearance: AppearanceSettingsModel.fromMap(appearance),
      python: PythonSettingsModel.fromMap(python),
      cache: CacheSettingsModel.fromMap(cache),
      mcp: McpSettingsModel.fromMap(mcp),
    );
  }
}
