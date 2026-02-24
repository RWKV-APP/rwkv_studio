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
      decodeParamPresets: (fields[0] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, StateCacheBox obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.decodeParamPresets);
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
