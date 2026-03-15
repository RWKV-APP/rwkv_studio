import 'package:hive_ce/hive.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

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
  int updateAt;

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

  @HiveField(10)
  int createAt;

  @HiveField(11)
  String reasoning;

  MessageBox({
    required this.id,
    required this.convId,
    required this.text,
    required this.thinkEndAt,
    required this.role,
    required this.error,
    required this.modelName,
    required this.stopReason,
    required this.extra,
    this.createAt = 0,
    this.updateAt = 0,
    this.reasoning = '',
  });

  static Box<MessageBox>? _messageBox;

  static Future<Box<MessageBox>> _instance() async {
    try {
      _messageBox ??= await Hive.openBox<MessageBox>('messages');
    } catch (e, s) {
      throw AppException.storage(
        'Failed to open message box',
        cause: e,
        stackTrace: s,
      );
    }
    return _messageBox!;
  }

  static Future clear() => Hive.deleteBoxFromDisk('messages');

  static Future put(MessageModel message) async {
    final box = await _instance();
    box.put(message.id, MessageBox.fromMessage(message));
  }

  static Future delete(String id) async {
    final box = await _instance();
    logi('delete message: $id');
    await box.delete(id);
  }

  static Future<Iterable<MessageBox>> getAll() async {
    final box = await _instance();
    final messages = box.values;
    return messages;
  }

  factory MessageBox.fromMessage(MessageModel message) {
    return MessageBox(
      id: message.id,
      convId: message.convId,
      text: message.text,
      thinkEndAt: message.thinkEndAt,
      updateAt: message.updateAt.millisecondsSinceEpoch,
      role: message.role,
      error: message.error,
      modelName: message.modelName,
      // avoid incorrect state.
      stopReason: !message.stopped
          ? StopReason.unknown.index
          : message.stopReason.index,
      createAt: message.createAt.millisecondsSinceEpoch,
      extra: Map<String, dynamic>.from(message.extra),
      reasoning: message.reasoning.name,
    );
  }

  MessageModel toMessage() {
    return MessageModel.create(
      role: role,
      convId: convId,
      text: text,
      modelName: modelName,
      reasoning: ReasoningEffort.fromName(reasoning),
    ).copyWith(
      id: id,
      thinkEndAt: thinkEndAt,
      createAt: DateTime.fromMillisecondsSinceEpoch(createAt),
      updateAt: DateTime.fromMillisecondsSinceEpoch(updateAt),
      error: error,
      stopReason: StopReason.values[stopReason],
      extra: extra,
    );
  }
}
