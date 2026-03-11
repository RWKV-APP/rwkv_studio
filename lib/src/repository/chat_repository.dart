import 'package:rwkv_studio/src/models/chat/chat_models.dart';

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
    return ChatPersistenceSnapshot.empty();
  }

  Future<void> saveConversation(ConversationModel conversation) async {}

  Future<void> saveConversations(
    Iterable<ConversationModel> conversations,
  ) async {}

  Future<void> deleteConversation(String id) async {}

  Future<void> saveMessage(MessageModel message) async {}

  Future<void> saveMessages(Iterable<MessageModel> messages) async {}

  Future<void> deleteMessage(String id) async {}

  Future<void> clearMessages() async {}
}
