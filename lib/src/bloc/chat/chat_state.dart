part of 'chat_cubit.dart';

class ChatState {
  final bool initialized;

  final List<ConversationState> conversations;
  final Map<String, List<MessageState>> messages;
  final ConversationState selected;
  final GenerationConfig generationConfig;
  final bool generating;
  final bool showSettingPanel;
  final bool showConversationList;

  final TextEditingController inputController;
  final FocusNode inputFocusNode;

  final ModelLoadState modelState;

  String get modelInstanceId => modelState.instanceId;

  List<MessageState> get currentChat => messages[selected.id] ?? [];

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
  });

  ChatState.empty()
      : this(
    initialized: false,
    showSettingPanel: false,
    conversations: [],
    selected: ConversationState.empty,
    messages: {},
    inputController: TextEditingController(),
    generating: false,
    generationConfig: GenerationConfig.initial(),
    modelState: ModelLoadState.empty(),
    inputFocusNode: FocusNode(),
    showConversationList: true,
  );

  ChatState copyWith({
    bool? initialized,
    List<ConversationState>? conversations,
    Map<String, List<MessageState>>? messages,
    ConversationState? selected,
    TextEditingController? inputController,
    bool? generating,
    GenerationConfig? generationConfig,
    bool? showSettingPanel,
    ModelLoadState? modelState,
    FocusNode? inputFocusNode,
    bool? showConversationList
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
    );
  }
}
