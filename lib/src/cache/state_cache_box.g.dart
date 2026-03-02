// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_cache_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StateCacheBoxAdapter extends TypeAdapter<StateCacheBox> {
  @override
  final typeId = 6;

  @override
  StateCacheBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StateCacheBox(
      key: fields[0] as String,
      value: fields[1] as String,
      updateAt: (fields[3] as num).toInt(),
      type: fields[2] as String,
      nameSpace: fields[4] == null ? '' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StateCacheBox obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.updateAt)
      ..writeByte(4)
      ..write(obj.nameSpace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateCacheBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
