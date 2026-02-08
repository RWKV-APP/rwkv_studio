// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preferences_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PreferencesBoxAdapter extends TypeAdapter<PreferencesBox> {
  @override
  final typeId = 1;

  @override
  PreferencesBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PreferencesBox(
      model: (fields[0] as Map).cast<String, dynamic>(),
      appearance: (fields[1] as Map).cast<String, dynamic>(),
      python: (fields[2] as Map).cast<String, dynamic>(),
      cache: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PreferencesBox obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.model)
      ..writeByte(1)
      ..write(obj.appearance)
      ..writeByte(2)
      ..write(obj.python)
      ..writeByte(3)
      ..write(obj.cache);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreferencesBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
