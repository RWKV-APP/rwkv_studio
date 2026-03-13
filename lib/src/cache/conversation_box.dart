import 'package:hive_ce/hive.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';

part 'conversation_box.g.dart';

@HiveType(typeId: 2)
class ConversationBox {
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
    await HiveManager.conversationBox.put(
      conv.id,
      ConversationBox.fromChat(conv),
    );
  }

  static Future delete(String id) async {
    await HiveManager.conversationBox.delete(id);
  }

  static Iterable<ConversationBox> getAll() {
    return HiveManager.conversationBox.values;
  }

  static Future clear() async {
    await HiveManager.conversationBox.clear();
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
