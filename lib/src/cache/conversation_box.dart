import 'package:hive_ce/hive.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';

part 'conversation_box.g.dart';

@HiveType(typeId: 2)
class ConversationBox {
  static const _boxName = 'conversations';
  static Box<ConversationBox>? _box;
  static Future<Box<ConversationBox>>? _openingBox;

  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime updateAt;

  @HiveField(3)
  String systemPrompt;

  @HiveField(4)
  String modelId;

  @HiveField(5)
  String decodeParmaId;

  @HiveField(6)
  int pinned;

  @HiveField(7)
  bool useGlobalSystemPrompt;

  ConversationBox({
    required this.id,
    required this.title,
    required this.updateAt,
    required this.systemPrompt,
    required this.modelId,
    required this.decodeParmaId,
    required this.pinned,
    required this.useGlobalSystemPrompt,
  });

  static Future<Box<ConversationBox>> _instance() async {
    final box = _box;
    if (box != null) {
      if (box.isOpen) {
        return box;
      }
      _box = null;
      _openingBox = null;
    }

    final openingBox = _openingBox;
    if (openingBox != null) {
      return openingBox;
    }

    final future = Hive.openBox<ConversationBox>(_boxName);
    _openingBox = future;
    try {
      final openedBox = await future;
      _box = openedBox;
      return openedBox;
    } catch (e, s) {
      _openingBox = null;
      Error.throwWithStackTrace(
        AppException.storage(
          'Failed to open conversation box',
          cause: e,
          stackTrace: s,
        ),
        s,
      );
    }
  }

  factory ConversationBox.fromChat(ConversationModel conv) {
    return ConversationBox(
      id: conv.id,
      title: conv.title,
      updateAt: conv.updateAt,
      systemPrompt: conv.systemPrompt,
      modelId: conv.modelId,
      decodeParmaId: conv.decodeParamId,
      pinned: conv.pinned,
      useGlobalSystemPrompt: conv.useGlobalSystemPrompt,
    );
  }

  static Future put(ConversationModel conv) async {
    final box = await _instance();
    await box.put(
      conv.id,
      ConversationBox.fromChat(conv),
    );
  }

  static Future delete(String id) async {
    final box = await _instance();
    await box.delete(id);
  }

  static Future<List<ConversationBox>> getAll() async {
    final box = await _instance();
    return box.values.toList();
  }

  static Future clear() async {
    final box = await _instance();
    await box.clear();
  }

  ConversationModel toChat() {
    return ConversationModel(
      id: id,
      title: title,
      updateAt: updateAt,
      systemPrompt: systemPrompt,
      modelId: modelId,
      decodeParamId: decodeParmaId,
      pinned: pinned,
      useGlobalSystemPrompt: useGlobalSystemPrompt,
    );
  }
}
