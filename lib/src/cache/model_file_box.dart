


import 'package:hive_ce/hive.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';

part 'model_file_box.g.dart';

@HiveType(typeId: 5)
class ModelFileBox {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  num modelSize;

  @HiveField(3)
  num fileSize;

  @HiveField(4)
  String url;

  @HiveField(5)
  String md5;

  @HiveField(6)
  String sha256;

  @HiveField(7)
  String quantization;

  @HiveField(8)
  String backend;

  @HiveField(9)
  List<String> tags;

  @HiveField(10)
  List<String> groups;

  @HiveField(11)
  List<String> decodeParams;

  @HiveField(12)
  bool isDebug;

  @HiveField(13)
  int updatedAt;

  @HiveField(14)
  String description;

  @HiveField(15)
  String vocabUrl;

  @HiveField(16)
  String vocabId;

  @HiveField(17)
  String localPath;

  ModelFileBox({
    required this.id,
    required this.name,
    required this.modelSize,
    required this.fileSize,
    required this.url,
    required this.md5,
    required this.sha256,
    required this.quantization,
    required this.backend,
    required this.tags,
    required this.groups,
    required this.decodeParams,
    required this.isDebug,
    required this.updatedAt,
    required this.description,
    required this.vocabUrl,
    required this.vocabId,
    required this.localPath,
  });

  factory ModelFileBox.fromModelInfo(ModelInfo info) {
    return ModelFileBox(
      id: info.id,
      name: info.name,
      modelSize: info.modelSize,
      fileSize: info.fileSize,
      url: info.url,
      md5: info.md5,
      sha256: info.sha256,
      quantization: info.quantization,
      backend: info.backend.name,
      tags: List<String>.from(info.tags),
      groups: List<String>.from(info.groups),
      decodeParams: List<String>.from(info.decodeParams),
      isDebug: info.isDebug,
      updatedAt: info.updatedAt,
      description: info.description,
      vocabUrl: info.vocabUrl,
      vocabId: info.vocabId,
      localPath: info.localPath,
    );
  }

  ModelInfo toModelInfo() {
    return ModelInfo(
      id: id,
      name: name,
      modelSize: modelSize,
      url: url,
      vocabUrl: vocabUrl,
      vocabId: vocabId,
      decodeParams: List<String>.from(decodeParams),
      sha256: sha256,
      md5: md5,
      fileSize: fileSize,
      quantization: quantization,
      backend: ModelBackend.fromString(backend),
      tags: List<String>.from(tags),
      groups: List<String>.from(groups),
      isDebug: isDebug,
      updatedAt: updatedAt,
      description: description,
      localPath: localPath,
    );
  }

  static Future put(ModelInfo info) async {
    await HiveManager.modelFileBox.put(
      info.id,
      ModelFileBox.fromModelInfo(info),
    );
  }

  static Future delete(String id) async {
    await HiveManager.modelFileBox.delete(id);
  }

  static Iterable<ModelFileBox> getAll() {
    return HiveManager.modelFileBox.values;
  }

  static Iterable<ModelInfo> getAllModels() {
    return getAll().map((e) => e.toModelInfo());
  }
}
