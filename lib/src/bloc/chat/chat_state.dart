part of 'chat_cubit.dart';

class ChatState {
  final bool initialized;

  final List<ConversationModel> conversations;
  final Map<String, List<MessageModel>> messages;
  final ConversationModel selected;
  final GenerationConfig generationConfig;
  final bool generating;
  final bool showSettingPanel;
  final bool showConversationList;

  final int maxChatHistoryLength;

  final TextEditingController inputController;
  final FocusNode inputFocusNode;

  final ModelLoadState modelState;

  String get modelInstanceId => modelState.instanceId;

  List<MessageModel> get currentChat => messages[selected.id] ?? [];

  bool get sendButtonEnabled => modelInstanceId.isNotEmpty && !generating;

  const ChatState({
    required this.initialized,
    required this.showSettingPanel,
    required this.conversations,
    required this.selected,
    required this.messages,
    required this.inputController,
    required this.generationConfig,
    required this.generating,
    required this.modelState,
    required this.inputFocusNode,
    required this.showConversationList,
    required this.maxChatHistoryLength,
  });

  ChatState.empty()
    : this(
        initialized: false,
        showSettingPanel: false,
        conversations: [],
        selected: ConversationModel.empty,
        messages: {},
        inputController: TextEditingController(),
        generating: false,
        generationConfig: const GenerationConfig(),
        modelState: ModelLoadState.empty(),
        inputFocusNode: FocusNode(),
        showConversationList: false,
        maxChatHistoryLength: 6,
      );

  ChatState copyWith({
    bool? initialized,
    List<ConversationModel>? conversations,
    Map<String, List<MessageModel>>? messages,
    ConversationModel? selected,
    TextEditingController? inputController,
    bool? generating,
    GenerationConfig? generationConfig,
    bool? showSettingPanel,
    ModelLoadState? modelState,
    FocusNode? inputFocusNode,
    bool? showConversationList,
    int? maxChatHistoryLength,
  }) {
    return ChatState(
      initialized: initialized ?? this.initialized,
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      selected: selected ?? this.selected,
      inputController: inputController ?? this.inputController,
      generating: generating ?? this.generating,
      generationConfig: generationConfig ?? this.generationConfig,
      showSettingPanel: showSettingPanel ?? this.showSettingPanel,
      inputFocusNode: inputFocusNode ?? this.inputFocusNode,
      modelState: modelState ?? this.modelState,
      showConversationList: showConversationList ?? this.showConversationList,
      maxChatHistoryLength: maxChatHistoryLength ?? this.maxChatHistoryLength,
    );
  }
}
