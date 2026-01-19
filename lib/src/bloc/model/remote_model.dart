import 'package:rwkv_downloader/rwkv_downloader.dart';

class RemoteModelProviderInfo {
  final String name;
  final String url;
  final String serviceId;

  RemoteModelProviderInfo({
    required this.name,
    required this.url,
    required this.serviceId,
  });
}

class RemoteModelInfo extends ModelInfo {
  String providerName = '';
  String serviceId = '';

  RemoteModelInfo({
    required super.id,
    required super.name,
    required super.modelSize,
    required super.url,
    required super.vocabUrl,
    required super.vocabId,
    required super.decodeParams,
    required super.sha256,
    required super.md5,
    required super.fileSize,
    required super.quantization,
    required super.backend,
    required super.tags,
    required super.groups,
    required super.isDebug,
    required super.updatedAt,
    required super.description,
    required super.localPath,
  });

  RemoteModelInfo.base({
    required super.id,
    required super.name,
    required super.url,
    super.modelSize = -1,
    super.vocabUrl = '',
    super.vocabId = '',
    super.decodeParams = const [],
    super.sha256 = '',
    super.md5 = '',
    super.fileSize = -1,
    super.quantization = '',
    super.backend = ModelBackend.unknown,
    super.tags = const [],
    super.groups = const [],
    super.isDebug = false,
    super.updatedAt = -1,
    super.description = '',
    super.localPath = '',
  });

  factory RemoteModelInfo.fromMap(dynamic map) {
    return RemoteModelInfo(
      id: map['id'] as String,
      name: map['name'] as String,
      url: map['url'] as String,
      vocabUrl: map['vocabUrl'] ?? '',
      vocabId: map['vocabId'] ?? '',
      modelSize: map['modelSize'] ?? -1,
      fileSize: map['fileSize'] ?? -1,
      quantization: map['quantization'] ?? '',
      backend: ModelBackend.fromString(map['backend']),
      tags: List<String>.from(map['tags'] ?? []),
      groups: List<String>.from(map['groups'] ?? []),
      decodeParams: List<String>.from(map['decodeParams'] ?? []),
      isDebug: map['isDebug'] ?? false,
      sha256: map['sha256'] ?? '',
      md5: map['md5'] ?? '',
      updatedAt: map['updatedAt'] ?? 0,
      description: map['description'] ?? '',
      localPath: map['path'] ?? '',
    );
  }
}
