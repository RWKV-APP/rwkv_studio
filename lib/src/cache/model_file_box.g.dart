// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_file_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ModelFileBoxAdapter extends TypeAdapter<ModelFileBox> {
  @override
  final int typeId = 5;

  @override
  ModelFileBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ModelFileBox(
      id: fields[0] as String,
      name: fields[1] as String,
      modelSize: fields[2] as num,
      fileSize: fields[3] as num,
      url: fields[4] as String,
      md5: fields[5] as String,
      sha256: fields[6] as String,
      quantization: fields[7] as String,
      backend: fields[8] as String,
      tags: (fields[9] as List).cast<String>(),
      groups: (fields[10] as List).cast<String>(),
      decodeParams: (fields[11] as List).cast<String>(),
      isDebug: fields[12] as bool,
      updatedAt: fields[13] as int,
      description: fields[14] as String,
      vocabUrl: fields[15] as String,
      vocabId: fields[16] as String,
      localPath: fields[17] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ModelFileBox obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.modelSize)
      ..writeByte(3)
      ..write(obj.fileSize)
      ..writeByte(4)
      ..write(obj.url)
      ..writeByte(5)
      ..write(obj.md5)
      ..writeByte(6)
      ..write(obj.sha256)
      ..writeByte(7)
      ..write(obj.quantization)
      ..writeByte(8)
      ..write(obj.backend)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.groups)
      ..writeByte(11)
      ..write(obj.decodeParams)
      ..writeByte(12)
      ..write(obj.isDebug)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.description)
      ..writeByte(15)
      ..write(obj.vocabUrl)
      ..writeByte(16)
      ..write(obj.vocabId)
      ..writeByte(17)
      ..write(obj.localPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelFileBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
