part of 'chat_cubit.dart';

class ConversationState {
  final String id;
  final String title;
  final DateTime updateAt;
  final String systemPrompt;
  final String modelId;
  final String decodeParamId;
  final int pinned;
  final bool useGlobalSystemPrompt;

  static ConversationState empty = ConversationState(
    id: '',
    title: '',
    updateAt: DateTime(0, 0),
    systemPrompt: '',
    modelId: '',
    pinned: 0,
    decodeParamId: '',
    useGlobalSystemPrompt: true,
  );

  ConversationState({
    required this.id,
    required this.title,
    required this.updateAt,
    required this.systemPrompt,
    required this.modelId,
    required this.pinned,
    required this.decodeParamId,
    required this.useGlobalSystemPrompt,
  });

  factory ConversationState.create() {
    return ConversationState(
      id: DateTime.now().toString(),
      title: '',
      updateAt: DateTime.now(),
      systemPrompt: '',
      modelId: '',
      decodeParamId: '',
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
      decodeParamId: decodeParmaId ?? this.decodeParamId,
      useGlobalSystemPrompt:
      useGlobalSystemPrompt ?? this.useGlobalSystemPrompt,
    );
  }
}