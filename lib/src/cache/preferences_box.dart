import 'package:hive_ce/hive_ce.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';

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

  static Future putRaw(SettingState value) {
    return HiveManager.preferencesBox.put(
      'default',
      PreferencesBox.fromSettingState(value),
    );
  }

  static Future<SettingState?> getRaw() async {
    final v = HiveManager.preferencesBox.get('default');
    return v?.toSettingState();
  }

  factory PreferencesBox.fromSettingState(SettingState state) {
    return PreferencesBox(
      model: state.model.toMap(),
      appearance: state.appearance.toMap(),
      python: state.python.toMap(),
      cache: state.cache.toMap(),
    );
  }

  SettingState toSettingState() {
    return SettingState(
      model: ModelSettingState.fromMap(model),
      appearance: AppearanceSettingState.fromMap(appearance),
      python: PythonSettingState.fromMap(python),
      cache: CacheSettingState.fromMap(cache),
      initialized: true,
    );
  }
}
