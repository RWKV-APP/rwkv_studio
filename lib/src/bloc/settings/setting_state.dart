part of 'setting_cubit.dart';

class RemoteService {
  final String id;
  final String name;
  final String url;
  final bool enabled;

  RemoteService({
    required this.url,
    required this.id,
    required this.name,
    required this.enabled,
  });

  RemoteService copyWith({
    String? url,
    String? id,
    String? name,
    bool? enabled,
  }) {
    return RemoteService(
      url: url ?? this.url,
      id: id ?? this.id,
      name: name ?? this.name,
      enabled: enabled ?? this.enabled,
    );
  }
}

class AppearanceSettingState {
  static final lightTheme = FluentThemeData.light();
  static final darkTheme = FluentThemeData.dark();

  final FluentThemeData theme;
  final String fontFamily;
  final int fontSize;

  AppearanceSettingState({
    required this.theme,
    required this.fontFamily,
    required this.fontSize,
  });

  factory AppearanceSettingState.initial() {
    return AppearanceSettingState(
      theme: AppearanceSettingState.lightTheme,
      fontFamily: 'Microsoft YaHei',
      fontSize: 16,
    );
  }

  AppearanceSettingState copyWith({
    FluentThemeData? theme,
    String? fontFamily,
    int? fontSize,
  }) {
    return AppearanceSettingState(
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class CacheSettingState {
  final String modelDownloadDir;
  final String appCacheDir;

  CacheSettingState({
    required this.modelDownloadDir,
    required this.appCacheDir,
  });

  factory CacheSettingState.initial() {
    return CacheSettingState(modelDownloadDir: '', appCacheDir: '');
  }
}

class SettingState {
  final List<RemoteService> remoteServices;
  final AppearanceSettingState appearance;
  final CacheSettingState cache;

  SettingState({
    required this.appearance,
    required this.cache,
    required this.remoteServices,
  });

  factory SettingState.initial() {
    return SettingState(
      appearance: AppearanceSettingState.initial(),
      cache: CacheSettingState.initial(),
      remoteServices: [],
    );
  }

  SettingState copyWith({
    AppearanceSettingState? appearance,
    CacheSettingState? cache,
    List<RemoteService>? remoteServices,
  }) {
    return SettingState(
      appearance: appearance ?? this.appearance,
      cache: cache ?? this.cache,
      remoteServices: remoteServices ?? this.remoteServices,
    );
  }
}
