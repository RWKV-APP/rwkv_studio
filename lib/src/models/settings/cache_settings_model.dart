import 'package:flutter/foundation.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class CacheSettingsModel extends Equatable {
  final String modelDownloadDir;
  final String appCacheDir;

  @override
  List<Object?> get props => [modelDownloadDir, appCacheDir];

  CacheSettingsModel({
    required this.modelDownloadDir,
    required this.appCacheDir,
  });

  factory CacheSettingsModel.initial() {
    if (!kIsWeb) {
      final defaultModelDir = pathJoin(appDataDir.path, 'models');
      final defaultCacheDir = pathJoin(appDataDir.path, 'cache');
      return CacheSettingsModel(
        modelDownloadDir: defaultModelDir,
        appCacheDir: defaultCacheDir,
      );
    }
    return CacheSettingsModel(modelDownloadDir: '', appCacheDir: '');
  }

  Map<String, dynamic> toMap() {
    return {'modelDownloadDir': modelDownloadDir, 'appCacheDir': appCacheDir};
  }

  factory CacheSettingsModel.fromMap(dynamic map) {
    if (map == null) {
      return CacheSettingsModel.initial();
    }
    return CacheSettingsModel(
      modelDownloadDir: map['modelDownloadDir'] as String,
      appCacheDir: map['appCacheDir'] as String,
    );
  }

  CacheSettingsModel copyWith({String? modelDownloadDir, String? appCacheDir}) {
    return CacheSettingsModel(
      modelDownloadDir: modelDownloadDir ?? this.modelDownloadDir,
      appCacheDir: appCacheDir ?? this.appCacheDir,
    );
  }
}
