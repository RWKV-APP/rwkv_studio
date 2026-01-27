part of 'chat_cubit.dart';

class MessageState {
  final String id;
  final String text;
  final int thinkEndAt;
  final DateTime datetime;
  final String role;
  final String error;
  final String modelName;
  final StopReason stopReason;
  final Map<String, dynamic> extra;

  bool get isUser => role == 'user';

  bool get hasThinkContent => thinkEndAt > 8;

  String get thinkContent {
    return text.substring(0, thinkEndAt).replaceAll('<think>', '').trim();
  }

  String get bodyContent {
    return text.substring(thinkEndAt).replaceAll('</think>', '').trim();
  }

  MessageState._({
    required this.id,
    required this.text,
    required this.datetime,
    required this.role,
    required this.modelName,
    this.thinkEndAt = 0,
    this.stopReason = StopReason.none,
    this.error = '',
    this.extra = const {},
  });

  static String _newId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  factory MessageState.create({
    required final String role,
    String? text,
    String? modelName,
  }) {
    final id = _newId();
    return MessageState._(
      id: id,
      text: text ?? '',
      datetime: DateTime.now(),
      role: role,
      stopReason: StopReason.none,
      error: '',
      extra: const {},
      modelName: modelName ?? '',
    );
  }

  MessageState copyWith({
    String? id,
    String? text,
    DateTime? datetime,
    String? role,
    String? error,
    String? modelName,
    StopReason? stopReason,
    Map<String, dynamic>? extra,
    int? thinkEndAt,
  }) {
    return MessageState._(
      id: id ?? this.id,
      text: text ?? this.text,
      datetime: datetime ?? this.datetime,
      role: role ?? this.role,
      error: error ?? this.error,
      modelName: modelName ?? this.modelName,
      stopReason: stopReason ?? this.stopReason,
      extra: extra ?? this.extra,
      thinkEndAt: thinkEndAt ?? this.thinkEndAt,
    );
  }
}

class ConversationState {
  final String id;
  final String title;
  final DateTime updateAt;

  static ConversationState empty = ConversationState(
    id: '',
    title: '',
    updateAt: DateTime(0, 0),
  );

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
  final ConversationState selected;
  final TextEditingController inputController;
  final DecodeParam decodeParam;
  final GenerationConfig generationConfig;
  final bool generating;
  final bool showSettingPanel;

  final ModelLoadState modelState;

  String get modelInstanceId => modelState.instanceId;

  List<MessageState> get currentChat => messages[selected.id] ?? [];

  bool get sendButtonEnabled => modelInstanceId.isNotEmpty && !generating;

  ChatState({
    required this.showSettingPanel,
    required this.conversations,
    required this.selected,
    required this.messages,
    required this.inputController,
    required this.decodeParam,
    required this.generationConfig,
    required this.generating,
    required this.modelState,
  });

  ChatState.empty()
    : this(
        showSettingPanel: false,
        conversations: [],
        selected: ConversationState.empty,
        messages: {},
        inputController: TextEditingController(),
        decodeParam: DecodeParam.initial(),
        generating: false,
        generationConfig: GenerationConfig.initial(),
        modelState: ModelLoadState.empty(),
      );

  ChatState copyWith({
    List<ConversationState>? conversations,
    Map<String, List<MessageState>>? messages,
    ConversationState? selected,
    TextEditingController? inputController,
    DecodeParam? decodeParam,
    bool? generating,
    GenerationConfig? generationConfig,
    bool? showSettingPanel,
    ModelLoadState? modelState,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selected: selected ?? this.selected,
      inputController: inputController ?? this.inputController,
      decodeParam: decodeParam ?? this.decodeParam,
      generating: generating ?? this.generating,
      generationConfig: generationConfig ?? this.generationConfig,
      showSettingPanel: showSettingPanel ?? this.showSettingPanel,
      modelState: modelState ?? this.modelState,
    );
  }
}
