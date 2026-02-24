// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageBoxAdapter extends TypeAdapter<MessageBox> {
  @override
  final typeId = 3;

  @override
  MessageBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MessageBox(
      id: fields[0] as String,
      convId: fields[9] as String,
      text: fields[1] as String,
      thinkEndAt: (fields[2] as num).toInt(),
      role: fields[4] as String,
      error: fields[5] as String,
      modelName: fields[6] as String,
      stopReason: (fields[7] as num).toInt(),
      extra: (fields[8] as Map).cast<String, dynamic>(),
      createAt: fields[10] == null ? 0 : (fields[10] as num).toInt(),
      updateAt: fields[3] == null ? 0 : (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, MessageBox obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.thinkEndAt)
      ..writeByte(3)
      ..write(obj.updateAt)
      ..writeByte(4)
      ..write(obj.role)
      ..writeByte(5)
      ..write(obj.error)
      ..writeByte(6)
      ..write(obj.modelName)
      ..writeByte(7)
      ..write(obj.stopReason)
      ..writeByte(8)
      ..write(obj.extra)
      ..writeByte(9)
      ..write(obj.convId)
      ..writeByte(10)
      ..write(obj.createAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
