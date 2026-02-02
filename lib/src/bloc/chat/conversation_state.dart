part of 'chat_cubit.dart';

class ConversationState {
  final String id;
  final String title;
  final DateTime updateAt;
  final String systemPrompt;
  final String modelId;
  final String decodeParmaId;
  final int pinned;
  final bool useGlobalSystemPrompt;

  static ConversationState empty = ConversationState(
    id: '',
    title: '',
    updateAt: DateTime(0, 0),
    systemPrompt: '',
    modelId: '',
    pinned: 0,
    decodeParmaId: '',
    useGlobalSystemPrompt: true,
  );

  ConversationState({
    required this.id,
    required this.title,
    required this.updateAt,
    required this.systemPrompt,
    required this.modelId,
    required this.pinned,
    required this.decodeParmaId,
    required this.useGlobalSystemPrompt,
  });

  factory ConversationState.create() {
    return ConversationState(
      id: DateTime.now().toString(),
      title: '',
      updateAt: DateTime.now(),
      systemPrompt: '',
      modelId: '',
      decodeParmaId: '',
      pinned: 0,
      useGlobalSystemPrompt: true,
    );
  }

  ConversationState copyWith({
    String? id,
    String? title,
    DateTime? updateAt,
    String? systemPrompt,
    String? modelId,
    int? pinned,
    String? decodeParmaId,
    bool? useGlobalSystemPrompt,
  }) {
    return ConversationState(
      id: id ?? this.id,
      title: title ?? this.title,
      updateAt: updateAt ?? this.updateAt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      modelId: modelId ?? this.modelId,
      pinned: pinned ?? this.pinned,
      decodeParmaId: decodeParmaId ?? this.decodeParmaId,
      useGlobalSystemPrompt:
      useGlobalSystemPrompt ?? this.useGlobalSystemPrompt,
    );
  }
}