class ConversationModel {
  final String id;
  final String title;
  final DateTime updateAt;
  final String systemPrompt;
  final String modelId;
  final String decodeParamId;
  final int pinned;
  final bool useGlobalSystemPrompt;

  static ConversationModel empty = ConversationModel(
    id: '',
    title: '',
    updateAt: DateTime(0, 0),
    systemPrompt: '',
    modelId: '',
    pinned: 0,
    decodeParamId: '',
    useGlobalSystemPrompt: true,
  );

  ConversationModel({
    required this.id,
    required this.title,
    required this.updateAt,
    required this.systemPrompt,
    required this.modelId,
    required this.pinned,
    required this.decodeParamId,
    required this.useGlobalSystemPrompt,
  });

  factory ConversationModel.create() {
    return ConversationModel(
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

  ConversationModel copyWith({
    String? id,
    String? title,
    DateTime? updateAt,
    String? systemPrompt,
    String? modelId,
    int? pinned,
    String? decodeParmaId,
    bool? useGlobalSystemPrompt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      updateAt: updateAt ?? this.updateAt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      modelId: modelId ?? this.modelId,
      pinned: pinned ?? this.pinned,
      decodeParamId: decodeParmaId ?? decodeParamId,
      useGlobalSystemPrompt:
          useGlobalSystemPrompt ?? this.useGlobalSystemPrompt,
    );
  }
}
