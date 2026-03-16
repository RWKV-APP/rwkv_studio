part of 'setting_cubit.dart';

class SettingState extends Equatable {
  final ModelSettingsModel model;
  final AppearanceSettingsModel appearance;
  final CacheSettingsModel cache;
  final PythonSettingsModel python;
  final McpSettingsModel mcp;

  final bool initialized;

  AppSettingsModel get settings => AppSettingsModel(
    model: model,
    appearance: appearance,
    cache: cache,
    python: python,
    mcp: mcp,
  );

  @override
  List<Object?> get props => [
    model,
    appearance,
    cache,
    python,
    mcp,
    initialized,
  ];

  SettingState({
    required this.appearance,
    required this.cache,
    required this.model,
    required this.python,
    required this.mcp,
    required this.initialized,
  });

  factory SettingState.initial() {
    return SettingState.fromSettings(AppSettingsModel.initial());
  }

  factory SettingState.fromSettings(
    AppSettingsModel settings, {
    bool initialized = false,
  }) {
    return SettingState(
      appearance: settings.appearance,
      cache: settings.cache,
      model: settings.model,
      python: settings.python,
      mcp: settings.mcp,
      initialized: initialized,
    );
  }

  SettingState copyWith({
    AppearanceSettingsModel? appearance,
    CacheSettingsModel? cache,
    ModelSettingsModel? model,
    PythonSettingsModel? python,
    McpSettingsModel? mcp,
    bool? initialized,
  }) {
    return SettingState(
      appearance: appearance ?? this.appearance,
      cache: cache ?? this.cache,
      model: model ?? this.model,
      python: python ?? this.python,
      mcp: mcp ?? this.mcp,
      initialized: initialized ?? this.initialized,
    );
  }

  Map<String, dynamic> toMap() {
    return settings.toMap();
  }

  factory SettingState.fromMap(Map<String, dynamic> map) {
    return SettingState.fromSettings(
      AppSettingsModel.fromMap(map),
      initialized: true,
    );
  }
}
