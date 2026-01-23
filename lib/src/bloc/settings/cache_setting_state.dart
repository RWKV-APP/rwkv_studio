part of 'setting_cubit.dart';

class CacheSettingState extends Equatable {
  final String modelDownloadDir;
  final String appCacheDir;

  @override
  List<Object?> get props => [modelDownloadDir, appCacheDir];

  CacheSettingState({
    required this.modelDownloadDir,
    required this.appCacheDir,
  });

  factory CacheSettingState.initial() {
    if (!kIsWeb) {
      final defaultModelDir = pathJoin(appExecutableDir.path, 'models');
      final defaultCacheDir = pathJoin(appExecutableDir.path, 'cache');
      return CacheSettingState(
        modelDownloadDir: defaultModelDir,
        appCacheDir: defaultCacheDir,
      );
    }
    return CacheSettingState(modelDownloadDir: '', appCacheDir: '');
  }

  Map<String, dynamic> toMap() {
    return {'modelDownloadDir': modelDownloadDir, 'appCacheDir': appCacheDir};
  }

  factory CacheSettingState.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return CacheSettingState.initial();
    }
    return CacheSettingState(
      modelDownloadDir: map['modelDownloadDir'] as String,
      appCacheDir: map['appCacheDir'] as String,
    );
  }

  CacheSettingState copyWith({String? modelDownloadDir, String? appCacheDir}) {
    return CacheSettingState(
      modelDownloadDir: modelDownloadDir ?? this.modelDownloadDir,
      appCacheDir: appCacheDir ?? this.appCacheDir,
    );
  }
}
