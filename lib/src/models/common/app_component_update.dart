import 'package:rwkv_studio/src/utils/equatable.dart';

class AppComponentInfo extends Equatable {
  final String componentName;
  final String entryPoint;
  final String description;
  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final int sizeBytes;
  final String sha256;
  final int timestamp;

  @override
  List<Object?> get props => [
    componentName,
    entryPoint,
    description,
    versionName,
    versionCode,
    downloadUrl,
    releaseNotes,
    sizeBytes,
    sha256,
    timestamp,
  ];

  const AppComponentInfo({
    required this.componentName,
    required this.entryPoint,
    required this.description,
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.sizeBytes,
    required this.sha256,
    required this.timestamp,
  });

  static const empty = AppComponentInfo(
    componentName: '',
    entryPoint: '',
    description: '',
    versionName: '',
    versionCode: 0,
    downloadUrl: '',
    releaseNotes: '',
    sizeBytes: 0,
    sha256: '',
    timestamp: 0,
  );

  Map toJson() => {
    'component_name': componentName,
    'entry_point': entryPoint,
    'description': description,
    'version_name': versionName,
    'version_code': versionCode,
    'download_url': downloadUrl,
    'release_notes': releaseNotes,
    'size_bytes': sizeBytes,
    'sha256': sha256,
    'timestamp': timestamp,
  };

  factory AppComponentInfo.fromJson(dynamic json) => AppComponentInfo(
    componentName: json['component_name'] ?? '',
    entryPoint: json['entry_point'] ?? '',
    description: json['description'] ?? '',
    versionName: json['version_name'] ?? '',
    versionCode: json['version_code'] ?? 0,
    downloadUrl: json['download_url'] ?? '',
    releaseNotes: json['release_notes'] ?? '',
    sizeBytes: json['size_bytes'] ?? 0,
    sha256: json['sha256'] ?? '',
    timestamp: json['timestamp'] ?? 0,
  );

  AppComponentInfo copyWith({
    String? componentName,
    String? entryPoint,
    String? description,
    String? versionName,
    int? versionCode,
    String? downloadUrl,
    String? releaseNotes,
    int? sizeBytes,
    String? sha256,
    int? timestamp,
  }) {
    return AppComponentInfo(
      componentName: componentName ?? this.componentName,
      entryPoint: entryPoint ?? this.entryPoint,
      description: description ?? this.description,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      releaseNotes: releaseNotes ?? this.releaseNotes,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
