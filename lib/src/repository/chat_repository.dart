import 'package:rwkv_studio/src/cache/conversation_box.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/cache/message_box.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';

class ChatPersistenceSnapshot {
  final List<ConversationModel> conversations;
  final Map<String, List<MessageModel>> messages;

  const ChatPersistenceSnapshot({
    this.conversations = const [],
    this.messages = const {},
  });

  factory ChatPersistenceSnapshot.empty() {
    return const ChatPersistenceSnapshot();
  }
}

class ChatRepository {
  const ChatRepository();

  Future<ChatPersistenceSnapshot> load() async {
    final convBox = await HiveManager.openConversationBox();
    final conversations = convBox.values.map((e) => e.toChat()).toList()
      ..sort((a, b) => b.updateAt.compareTo(a.updateAt));
    final messages = (await MessageBox.getAll())
        .map((e) => e.toMessage())
        .groupBy((e) => e.convId)
        .map((key, value) {
          final items = value.toList()
            ..sort((a, b) => a.updateAt.compareTo(b.updateAt));
          return MapEntry(key, items);
        });
    return ChatPersistenceSnapshot(
      conversations: conversations,
      messages: messages,
    );
  }

  Future<void> saveConversation(ConversationModel conversation) async {
    await HiveManager.openConversationBox();
    await ConversationBox.put(conversation);
  }

  Future<void> saveConversations(
    Iterable<ConversationModel> conversations,
  ) async {
    await HiveManager.openConversationBox();
    for (final conversation in conversations) {
      await ConversationBox.put(conversation);
    }
  }

  Future<void> deleteConversation(String id) async {
    await HiveManager.openConversationBox();
    await ConversationBox.delete(id);
  }

  Future<void> saveMessage(MessageModel message) async {
    await MessageBox.put(message);
  }

  Future<void> saveMessages(Iterable<MessageModel> messages) async {
    for (final message in messages) {
      await MessageBox.put(message);
    }
  }

  Future<void> deleteMessage(String id) async {
    await MessageBox.delete(id);
  }

  Future<void> clearMessages() async {
    await MessageBox.clear();
  }
}
