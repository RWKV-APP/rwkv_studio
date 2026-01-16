part of 'chat_cubit.dart';

class MessageState {
  final String id;
  final String text;
  final DateTime datetime;
  final String role;
  final String error;
  final String modelName;
  final StopReason stopReason;

  bool get isUser => role == 'user';

  MessageState({
    required this.id,
    required this.text,
    required this.datetime,
    required this.role,
    required this.modelName,
    this.stopReason = StopReason.none,
    this.error = '',
  });

  MessageState copyWith({
    String? id,
    String? text,
    DateTime? datetime,
    String? role,
    String? error,
    String? modelName,
    StopReason? stopReason,
  }) {
    return MessageState(
      id: id ?? this.id,
      text: text ?? this.text,
      datetime: datetime ?? this.datetime,
      role: role ?? this.role,
      error: error ?? this.error,
      modelName: modelName ?? this.modelName,
      stopReason: stopReason ?? this.stopReason,
    );
  }
}

class ConversationState {
  final String id;
  final String title;
  final DateTime updateAt;

  ConversationState({
    required this.id,
    required this.title,
    required this.updateAt,
  });

  ConversationState copyWith({String? id, String? title, DateTime? updateAt}) {
    return ConversationState(
      id: id ?? this.id,
      title: title ?? this.title,
      updateAt: updateAt ?? this.updateAt,
    );
  }
}

class ChatState {
  final List<ConversationState> conversations;
  final Map<String, List<MessageState>> messages;
  final String selected;
  final TextEditingController inputController;
  final String modelInstanceId;
  final DecodeParam decodeParam;
  final GenerationConfig generationConfig;
  final bool generating;
  final bool showSettingPanel;

  ChatState({
    required this.showSettingPanel,
    required this.conversations,
    required this.selected,
    required this.messages,
    required this.inputController,
    required this.modelInstanceId,
    required this.decodeParam,
    required this.generationConfig,
    required this.generating,
  });

  ChatState.empty()
    : this(
        showSettingPanel: false,
        conversations: [],
        selected: '',
        messages: {},
        inputController: TextEditingController(),
        modelInstanceId: '',
        decodeParam: DecodeParam.initial(),
        generating: false,
        generationConfig: GenerationConfig.initial(),
      );

  ChatState copyWith({
    List<ConversationState>? conversations,
    Map<String, List<MessageState>>? messages,
    String? selected,
    TextEditingController? inputController,
    String? modelInstanceId,
    DecodeParam? decodeParam,
    bool? generating,
    GenerationConfig? generationConfig,
    bool? showSettingPanel,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selected: selected ?? this.selected,
      inputController: inputController ?? this.inputController,
      modelInstanceId: modelInstanceId ?? this.modelInstanceId,
      decodeParam: decodeParam ?? this.decodeParam,
      generating: generating ?? this.generating,
      generationConfig: generationConfig ?? this.generationConfig,
      showSettingPanel: showSettingPanel ?? this.showSettingPanel,
    );
  }
}
