import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_interface.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/errors/assert.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';
import 'package:rwkv_studio/src/models/chat/message_content.dart';
import 'package:rwkv_studio/src/models/chat/tool_call_info.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/repository/repositories.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/diff_utils.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/rwkv_tokenizer.dart';
import 'package:rwkv_studio/src/utils/subscription_mixin.dart';
import 'package:rxdart/rxdart.dart';

export 'package:rwkv_studio/src/models/chat/chat_models.dart';

part 'chat_state.dart';

extension Ext on BuildContext {
  ChatCubit get chat => read<ChatCubit>();
}

class ChatCubit extends Cubit<ChatState> with SubscriptionManagerMixin {
  final ChatRepository _repository;
  final LlmSessionRepository _llmSessionRepository;

  ChatCubit(this._repository, this._llmSessionRepository)
    : super(ChatState.empty());

  Future initialized() async {
    if (state.initialized) {
      return;
    }
    await stream
        .where((e) => e.initialized)
        .first
        .timeout(const Duration(seconds: 10));
  }

  Future init() async {
    if (state.initialized) {
      return;
    }

    try {
      final snapshot = await _repository.load();
      logd(
        'restored conversations: ${snapshot.conversations.length},'
        ' messages: ${snapshot.messages.length}',
      );
      emit(
        state.copyWith(
          conversations: snapshot.conversations,
          messages: snapshot.messages,
        ),
      );
    } catch (e, s) {
      loge('failed to restore message', e, s);
    }
    _initStatePersistence();

    emit(state.copyWith(initialized: true));

    if (state.conversations.isEmpty) {
      await newChat();
    }
    selectConversation(state.conversations.first);

    state.inputController.addListener(() {
      _updateInputTokenCount();
    });
  }

  void _initStatePersistence() {
    final sp1 = stream
        .map((e) => e.conversations)
        .distinct((p, c) => p == c)
        .throttleTime(
          const Duration(milliseconds: 500),
          trailing: true,
          leading: false,
        )
        .diff(keyExtractor: (e) => e.id)
        .asyncMap((e) async {
          try {
            logi(
              'conversation changed, added: ${e.added.length}, changed: ${e.changed.length}, removed: ${e.removed.length}',
            );
            for (final conv in e.removed) {
              await _repository.deleteConversation(conv.id);
            }
            await _repository.saveConversations([...e.added, ...e.changed]);
          } catch (error, s) {
            final appError = AppException.wrap(error, s);
            loge(
              'ChatCubit persist conversations failed',
              appError,
              appError.stackTrace ?? s,
            );
          }
        })
        .listen((_) {});
    addSubscription(sp1);

    final sp2 = stream
        .distinct((p, c) => p.messages == c.messages)
        .throttleTime(
          const Duration(milliseconds: 1000),
          trailing: true,
          leading: false,
        )
        .map((e) => e.messages.values.flatten())
        .diff(keyExtractor: (e) => e.id)
        .asyncMap((e) async {
          try {
            for (final item in e.removed) {
              await _repository.deleteMessage(item.id);
              logd('delete message: ${item.id}');
            }
            await _repository.saveMessages([...e.added, ...e.changed]);
            if (e.added.isNotEmpty) {
              logd('add messages: ${e.added.length}');
            }
          } catch (error, s) {
            loge('ChatCubit persist messages failed', error, s);
          }
        })
        .listen((_) {});
    addSubscription(sp2);
  }

  void onModelReleased() {
    emit(state.copyWith(modelState: ModelLoadState.empty()));
  }

  Future loadModel(
    BuildContext context,
    LlmInterface llm,
    ModelInfo model,
  ) async {
    updateConversation(state.selected.id, (e) => e.copyWith(modelId: model.id));

    final sp = llm
        .loadOrGetModelInstance(context, model)
        .listen(
          (e) {
            emit(state.copyWith(modelState: e));
            // RWKV is not supported tool-call yet
            if (e.isRWKV && state.generationConfig.enableMcp) {
              final gc = state.generationConfig.copyWith(enableMcp: false);
              emit(state.copyWith(generationConfig: gc));
            }
            _updateInputTokenCount();
          },
          onError: (e, s) {
            final modelState = ModelLoadState.error(
              model.id,
              AppException.wrap(e, s),
            );
            emit(state.copyWith(modelState: modelState));
            _updateInputTokenCount();
          },
        );
    addSubscription(sp);
  }

  void toggleSettingPanelVisible() {
    emit(state.copyWith(showSettingPanel: !state.showSettingPanel));
  }

  void setDecodeParam(String param) {
    logi('set decode param preset to: $param');
    updateConversation(
      state.selected.id,
      (e) => e.copyWith(decodeParmaId: param),
    );
  }

  void setUseGlobalSystemPrompt(bool useGlobalSystemPrompt) {
    if (state.selected.useGlobalSystemPrompt == useGlobalSystemPrompt) {
      return;
    }
    updateConversation(
      state.selected.id,
      (e) => e.copyWith(useGlobalSystemPrompt: useGlobalSystemPrompt),
    );
  }

  void setSystemPrompt(String prompt) {
    if (state.selected.useGlobalSystemPrompt) {
      emit(
        state.copyWith(
          generationConfig: state.generationConfig.copyWith(prompt: prompt),
        ),
      );
    } else {
      updateConversation(
        state.selected.id,
        (e) => e.copyWith(systemPrompt: prompt),
      );
    }
  }

  void setMaxChatHistoryLength(int length) {
    if (length <= 0 || state.maxChatHistoryLength == length) {
      return;
    }
    emit(state.copyWith(maxChatHistoryLength: length));
  }

  void toggleConversationListVisible() {
    emit(state.copyWith(showConversationList: !state.showConversationList));
  }

  void toggleEnableMcp() {
    emit(
      state.copyWith(
        generationConfig: state.generationConfig.copyWith(
          enableMcp: !state.generationConfig.enableMcp,
        ),
      ),
    );
  }

  void toggleReasoningEnable() {
    final effort =
        state.generationConfig.reasoningEffort != ReasoningEffort.none
        ? ReasoningEffort.none
        : ReasoningEffort.high;
    setReasoningMode(effort);
  }

  void setReasoningMode(ReasoningEffort effort) {
    emit(
      state.copyWith(
        generationConfig: state.generationConfig.copyWith(
          reasoningEffort: effort,
        ),
      ),
    );
  }

  Future clear() async {
    await _repository.clear();
    emit(
      state.copyWith(
        messages: {},
        conversations: [],
        selected: ConversationModel.create(),
      ),
    );
    newChat();
  }

  Future newChat() async {
    final conv = ConversationModel.create();
    emit(
      state.copyWith(
        conversations: [conv, ...state.conversations],
        selected: conv,
      ),
    );
  }

  void selectConversation(ConversationModel conv) async {
    emit(state.copyWith(selected: conv));

    final instance = _llmSessionRepository.getInstanceByModelId(conv.modelId);
    if (instance != null) {
      emit(
        state.copyWith(
          modelState: ModelLoadState.loaded(
            instance.info.id,
            instance.info.name,
            instance.id,
            instance.info.providerName,
          ),
        ),
      );
    }
  }

  Future updateMessageContent(String id, String content) async {
    final convId = state.selected.id;
    final messages = state.messages[convId] ?? [];
    final msgs = messages.map((e) {
      if (e.id == id) {
        return e.copyWithEditContent(content: content);
      }
      return e;
    }).toList();
    emit(state.copyWith(messages: {...state.messages, convId: msgs}));
  }

  Future deleteMessage(String id) async {
    final convId = state.selected.id;
    final messages = state.messages[convId] ?? [];
    final msgs = messages.where((e) => e.id != id).toList();
    emit(state.copyWith(messages: {...state.messages, convId: msgs}));
  }

  Future deleteConversation(String id) async {
    ConversationModel selected = state.selected;
    final conversations = state.conversations.where((e) => e.id != id).toList();
    final messages = {...state.messages};
    if (selected.id == id) {
      selected = conversations.firstOrNull ?? ConversationModel.empty;
    }
    messages.remove(id);
    emit(
      state.copyWith(
        conversations: conversations,
        messages: messages,
        selected: selected,
      ),
    );
  }

  Future mayPause(LlmInterface llm) async {
    if (state.generating) {
      pause(llm, conversationId: state.selected.id);
    }
  }

  Future pause(LlmInterface llm, {String? conversationId}) async {
    await llm.stop(state.modelInstanceId);
    emit(state.copyWith(generating: false));
  }

  Future resume(LlmInterface llm) async {
    final convId = state.selected.id;
    final history = state.messages[convId]!;
    final generated = history.removeLast();
    await _sendInternal(llm, history, generated, convId);
  }

  Future regenerate(LlmInterface llm) async {
    if (state.generating) {
      return;
    }
    if (state.modelInstanceId.isEmpty) {
      throw const AppException.validation('请选择模型');
    }
    final convId = state.selected.id;

    final history = state.messages[convId]!;
    history.removeAt(history.length - 1);

    final model = await llm.getModelBaseInfo(state.modelInstanceId);
    MessageModel assistant = MessageModel.create(
      role: llm.roleAssistant,
      convId: convId,
      reasoning: state.generationConfig.reasoningEffort,
      modelName: model.name,
    );

    emit(
      state.copyWith(
        messages: {
          ...state.messages,
          convId: [...history, assistant],
        },
      ),
    );

    logi(
      'start chat regeneration, ${model.name} ${model.id}, history length: ${history.length}',
    );
    await _sendInternal(llm, history, assistant, convId);
  }

  void updateConversation(
    String id,
    ConversationModel Function(ConversationModel) update,
  ) {
    logi('updateConversation $id');
    ConversationModel? updated;
    final c = state.conversations.map((e) {
      if (e.id == id) {
        updated = update(e);
        return updated!;
      }
      return e;
    }).toList();
    c.sort((a, b) => b.updateAt.compareTo(a.updateAt));
    emit(
      state.copyWith(
        conversations: c,
        selected: state.selected.id == updated?.id ? updated : state.selected,
      ),
    );
  }

  Future send(LlmInterface llm) async {
    final text = state.inputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    if (state.modelInstanceId.isEmpty) {
      state.inputController.text = text;
      throw const AppException.validation('请选择模型');
    }

    String convId = state.selected.id;

    final model = await llm.getModelBaseInfo(state.modelInstanceId);
    final message = MessageModel.create(
      role: llm.roleUser,
      convId: convId,
      modelName: model.name,
      contents: [MessageContent.question(text)],
    );
    final history = <MessageModel>[...(state.messages[convId] ?? []), message];

    if (history.length == 1) {
      updateConversation(
        convId,
        (c) => c.copyWith(title: text, updateAt: DateTime.now()),
      );
    }
    emit(state.copyWith(messages: {...state.messages, convId: history}));

    MessageModel assistant = MessageModel.create(
      role: llm.roleAssistant,
      convId: convId,
      reasoning: state.generationConfig.reasoningEffort,
      modelName: model.name,
    );

    await _sendInternal(llm, history, assistant, convId);
  }

  Future _sendInternal(
    LlmInterface llm,
    List<MessageModel> history,
    MessageModel assistant,
    String convId,
  ) async {
    final conv = state.conversations.firstWhere((e) => e.id == convId);
    final systemPrompt = conv.useGlobalSystemPrompt ? null : conv.systemPrompt;

    assistant = assistant.copyWith(stopReason: StopReason.none);
    logd(
      "start chat: conv-id:$convId, model:${state.modelState.modelName}, decode_param=${conv.decodeParamId}",
    );
    final stream = llm.chat(
      history,
      state.modelInstanceId,
      conv.decodeParamId,
      state.generationConfig.copyWith(prompt: systemPrompt),
    );

    Future.delayed(const Duration(milliseconds: 20), () {
      state.inputController.clear();
    });

    emit(
      state.copyWith(
        generating: true,
        messages: {
          ...state.messages,
          convId: [...history, assistant],
        },
      ),
    );
    try {
      var receivedTerminalEvent = false;
      await for (final event in stream) {
        if (isClosed) {
          return;
        }
        receivedTerminalEvent =
            _onChatEvent(
              conversationId: convId,
              history: history,
              event: event,
            ) ||
            receivedTerminalEvent;
      }
      if (!receivedTerminalEvent) {
        _onGenerateDone(conversationId: convId, history: history);
      }
    } catch (e, s) {
      final error = AppException.wrap(e, s);
      logw('chat generation error: ${error.kind}, ${error.message}');
      _onGenerateError(conversationId: convId, history: history, e: error);
      // Error.throwWithStackTrace(error, error.stackTrace ?? s);
    } finally {
      var assistant = state.messages[convId]!.last;
      logd('chat generation completed: stop_reason:${assistant.stopReason}');

      if (state.modelState.isRWKV) {
        try {
          // Token counting post-processing currently uses the RWKV tokenizer only.
          // FIXME
          final count = RwkvTokenizer.default_.tokenCount(
            assistant.copyClipboardText(),
          );
          assistant = assistant.copyWithTokenCount(count);
        } catch (e, s) {
          final error = AppException.wrap(e, s);
          loge('ChatCubit token count failed', error, error.stackTrace ?? s);
        }
      }

      final contents = assistant.contents.toList();
      for (var i = 0; i < contents.length; i++) {
        final content = contents[i];
        if (!content.completed) {
          contents[i] = content.copyWith(completed: true);
        }
      }

      assistant = assistant.copyWith(contents: contents);
      emit(
        state.copyWith(
          generating: false,
          messages: {
            ...state.messages,
            convId: [...history, assistant],
          },
        ),
      );
    }
  }

  bool _onChatEvent({
    required String conversationId,
    required List<MessageModel> history,
    required ChatEvent event,
  }) {
    switch (event) {
      case ChatAssistantEvent():
        _onAssistantDelta(
          conversationId: conversationId,
          history: history,
          event: event,
        );
        return false;
      case ChatCompletedEvent():
        _onGenerateDone(
          conversationId: conversationId,
          history: history,
          stopReason: event.stopReason,
        );
        return true;
      case ChatFailedEvent():
        _onGenerateError(
          conversationId: conversationId,
          history: history,
          e: AppException.internal(event.error),
        );
        return true;
      case ChatToolCallEvent():
        _onToolCall(
          conversationId: conversationId,
          history: history,
          event: event,
        );
        return false;
      case ChatToolResultEvent():
        _onToolResult(
          conversationId: conversationId,
          history: history,
          event: event,
        );
        return false;
    }
  }

  void _onAssistantDelta({
    required String conversationId,
    required List<MessageModel> history,
    required ChatAssistantEvent event,
  }) {
    var assistant = state.messages[conversationId]!.last;
    var contents = assistant.contents.toList();

    if (event.hasReasoningDelta) {
      contents = _appendAssistantTextContent(
        contents,
        type: ContentType.think,
        delta: event.reasoningDelta,
        round: event.round,
      );
    }
    if (event.hasContentDelta) {
      contents = _completeAssistantReasoning(contents);
      contents = _appendAssistantTextContent(
        contents,
        type: ContentType.answer,
        delta: event.contentDelta,
        round: event.round,
      );
    }

    if (!event.hasDelta && event.tokenCount <= 0) {
      return;
    }

    assistant = assistant.copyWith(contents: contents);
    if (event.tokenCount > 0) {
      assistant = assistant.copyWithTokenCount(event.tokenCount);
    }
    emit(
      state.copyWith(
        generating: true,
        messages: {
          ...state.messages,
          conversationId: [...history, assistant],
        },
      ),
    );
  }

  List<MessageContent> _completeAssistantReasoning(
    List<MessageContent> contents,
  ) {
    final last = contents.lastOrNull;
    if (last?.type != ContentType.think || last!.completed) {
      return contents;
    }

    final next = contents.toList();
    next[next.length - 1] = last.copyWith(completed: true);
    return next;
  }

  List<MessageContent> _appendAssistantTextContent(
    List<MessageContent> contents, {
    required ContentType type,
    required String delta,
    int? round,
  }) {
    if (delta.isEmpty) {
      return contents;
    }

    final next = contents.toList();
    final last = next.lastOrNull;

    if (last?.type == type && last!.isTextContent) {
      next[next.length - 1] = last.copyWith(
        data: last.text + delta,
        round: round ?? last.round,
        completed: false,
      );
      return next;
    }

    final newContent = switch (type) {
      ContentType.think => MessageContent.think(delta, round: round),
      ContentType.answer => MessageContent.answer(delta, round: round),
      _ => throw StateError('Unsupported assistant content type: $type'),
    };
    next.add(newContent);
    return next;
  }

  void _onGenerateDone({
    required String conversationId,
    required List<MessageModel> history,
    StopReason? stopReason,
  }) {
    var assistant = state.messages[conversationId]!.last;
    updateConversation(
      conversationId,
      (c) => c.copyWith(updateAt: DateTime.now()),
    );
    var ns = state.copyWith(generating: false);
    if (assistant.stopReason == StopReason.none) {
      assistant = assistant.copyWith(
        stopReason: stopReason ?? StopReason.unknown,
      );
    }
    assistant = assistant.copyWith(updateAt: DateTime.now());
    ns = ns.copyWith(
      messages: {
        ...state.messages,
        conversationId: [...history, assistant],
      },
    );

    logd('chat generation done: ${assistant.stopReason}');
    emit(ns);
  }

  void _onGenerateError({
    required String conversationId,
    required List<MessageModel> history,
    required dynamic e,
  }) {
    final error = e is AppException ? e : AppException.wrap(e);
    var assistant = state.messages[conversationId]!.last;
    assistant = assistant.copyWith(updateAt: DateTime.now());
    if (isCanceledException(error)) {
      assistant = assistant.copyWith(
        stopReason: StopReason.canceled,
        contents: [...assistant.contents, .error(e)],
      );
    } else {
      assistant = assistant.copyWith(
        error: error.displayMessage,
        stopReason: StopReason.error,
        contents: [...assistant.contents, .error(e)],
      );
    }
    updateConversation(
      conversationId,
      (c) => c.copyWith(updateAt: DateTime.now()),
    );
    emit(
      state.copyWith(
        generating: false,
        messages: {
          ...state.messages,
          conversationId: [...history, assistant],
        },
      ),
    );
  }

  void _onToolCall({
    required String conversationId,
    required List<MessageModel> history,
    required ChatToolCallEvent event,
  }) {
    var assistant = state.messages[conversationId]!.last;

    assistant = assistant.copyWith(
      contents: [
        ...assistant.contents.map(
          (e) => e.completed ? e : e.copyWith(completed: true),
        ),
        MessageContent.toolCall(ToolCallInfo.fromCall(event.toolCall)),
      ],
    );
    emit(
      state.copyWith(
        generating: true,
        messages: {
          ...state.messages,
          conversationId: [...history, assistant],
        },
      ),
    );
  }

  void _onToolResult({
    required String conversationId,
    required List<MessageModel> history,
    required ChatToolResultEvent event,
  }) {
    var assistant = state.messages[conversationId]!.last;

    final last = assistant.contents.lastOrNull;
    if (last?.type == .toolCall) {
      final contents = assistant.contents.toList();
      contents.removeLast();
      assistant = assistant.copyWith(
        contents: [
          ...contents,
          last!.copyWith(
            data: last.toolInfo.copyWithResult(event.result),
            completed: true,
          ),
        ],
      );
    }

    emit(
      state.copyWith(
        generating: true,
        messages: {
          ...state.messages,
          conversationId: [...history, assistant],
        },
      ),
    );
  }

  void _updateInputTokenCount() {
    if (state.modelInstanceId.isEmpty) {
      return;
    }
    final text = state.inputController.text.trim();
    final tokenCount = _llmSessionRepository.getTokenCount(
      state.modelInstanceId,
      text,
    );
    emit(state.copyWith(inputTokenCount: tokenCount));
  }
}
