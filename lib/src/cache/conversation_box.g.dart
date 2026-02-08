// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_box.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationBoxAdapter extends TypeAdapter<ConversationBox> {
  @override
  final typeId = 2;

  @override
  ConversationBox read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationBox(
      id: fields[0] as String,
      title: fields[1] as String,
      updateAt: fields[2] as DateTime,
      systemPrompt: fields[3] as String,
      modelId: fields[4] as String,
      decodeParmaId: fields[5] as String,
      pinned: (fields[6] as num).toInt(),
      useGlobalSystemPrompt: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationBox obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.updateAt)
      ..writeByte(3)
      ..write(obj.systemPrompt)
      ..writeByte(4)
      ..write(obj.modelId)
      ..writeByte(5)
      ..write(obj.decodeParmaId)
      ..writeByte(6)
      ..write(obj.pinned)
      ..writeByte(7)
      ..write(obj.useGlobalSystemPrompt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationBoxAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
