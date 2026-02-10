import 'package:hive_ce/hive.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

import 'hive_manager.dart';

part 'message_box.g.dart';

@HiveType(typeId: 3)
class MessageBox {
  @HiveField(0)
  String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  int thinkEndAt;

  @HiveField(3)
  DateTime datetime;

  @HiveField(4)
  String role;

  @HiveField(5)
  String error;

  @HiveField(6)
  String modelName;

  @HiveField(7)
  int stopReason;

  @HiveField(8)
  Map<String, dynamic> extra;

  @HiveField(9)
  String convId;

  MessageBox({
    required this.id,
    required this.convId,
    required this.text,
    required this.thinkEndAt,
    required this.datetime,
    required this.role,
    required this.error,
    required this.modelName,
    required this.stopReason,
    required this.extra,
  });

  static Future put(MessageState message) async {
    await HiveManager.messageBox.put(
      message.id,
      MessageBox.fromMessage(message),
    );
  }

  static Future delete(String id) async {
    logi('delete message: $id');
    await HiveManager.messageBox.delete(id);
  }

  factory MessageBox.fromMessage(MessageState message) {
    return MessageBox(
      id: message.id,
      convId: message.convId,
      text: message.text,
      thinkEndAt: message.thinkEndAt,
      datetime: message.updateAt,
      role: message.role,
      error: message.error,
      modelName: message.modelName,
      stopReason: message.stopReason.index,
      extra: Map<String, dynamic>.from(message.extra),
    );
  }

  MessageState toMessage() {
    return MessageState.create(
      role: role,
      convId: convId,
      text: text,
      modelName: modelName,
    ).copyWith(
      id: id,
      thinkEndAt: thinkEndAt,
      updateAt: datetime,
      error: error,
      stopReason: StopReason.values[stopReason],
      extra: extra,
    );
  }
}
