import 'package:rwkv_downloader/rwkv_downloader.dart';

class RemoteModelInfo extends ModelInfo {
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
}
