import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/errors/assert.dart';
import 'package:rwkv_studio/src/models/chat/chat_models.dart';
import 'package:rwkv_studio/src/models/llm/generation_config.dart';
import 'package:rwkv_studio/src/repository/chat_repository.dart';
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

  ChatCubit(this._repository) : super(ChatState.empty());

  Future init() async {
    if (state.initialized) {
      return;
    }

    emit(state.copyWith(initialized: true));

    final snapshot = await _repository.load();
    final convs = snapshot.conversations;
    final msgs = snapshot.messages;
    logd('restored conversations: ${convs.length}, messages: ${msgs.length}');
    emit(state.copyWith(conversations: convs, messages: msgs));

    if (state.conversations.isEmpty) {
      await newChat();
    }
    selectConversation(state.conversations.first);

    _initStatePersistence();
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
          } catch (error, stackTrace) {
            loge(error, stackTrace);
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
          } catch (error, stackTrace) {
            loge(error, stackTrace);
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
    RwkvInterface rwkv,
    ModelInfo model,
  ) async {
    final sp = rwkv
        .loadOrGetModelInstance(context, model)
        .listen(
          (e) {
            emit(state.copyWith(modelState: e));
          },
          onError: (e, s) {
            emit(state.copyWith(modelState: ModelLoadState.error(model.id, e)));
          },
        );
    addSubscription(sp);
  }

  void toggleSettingPanelVisible() {
    emit(state.copyWith(showSettingPanel: !state.showSettingPanel));
  }

  void setDecodeParam(String param) {
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

  void toggleConversationListVisible() {
    emit(state.copyWith(showConversationList: !state.showConversationList));
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
    await _repository.clearMessages();
    emit(state.copyWith(messages: {}));
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

  void selectConversation(ConversationModel conv) {
    emit(state.copyWith(selected: conv));
  }

  Future updateMessageContent(String id, String content) async {
    final convId = state.selected.id;
    final messages = state.messages[convId] ?? [];
    final msgs = messages.map((e) {
      if (e.id == id) {
        return e.copyWith(text: content);
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

  Future mayPause(RwkvInterface rwkv) async {
    if (state.generating) {
      pause(rwkv, conversationId: state.selected.id);
    }
  }

  Future pause(RwkvInterface rwkv, {String? conversationId}) async {
    final convId = conversationId ?? state.selected.id;
    await rwkv.stop(state.modelInstanceId);
    emit(state.copyWith(generating: false));
    await Future.delayed(const Duration(milliseconds: 100));
    final history = state.messages[convId] ?? [];
    final last = history.lastOrNull;
    if (last == null) {
      logw('pause message cannot be found');
      return;
    }
    emit(
      state.copyWith(
        messages: {
          ...state.messages,
          convId: [
            ...history.take(history.length - 1),
            last.copyWith(stopReason: StopReason.canceled),
          ],
        },
      ),
    );
  }

  Future resume(RwkvInterface rwkv) async {
    final convId = state.selected.id;
    final history = state.messages[convId]!;
    final generated = history.removeLast();
    await _sendInternal(rwkv, history, generated, convId);
  }

  Future regenerate(RwkvInterface rwkv) async {
    if (state.generating) {
      return;
    }
    if (state.modelInstanceId.isEmpty) {
      throw '请选择模型';
    }
    final convId = state.selected.id;

    final history = state.messages[convId]!;
    history.removeAt(history.length - 1);

    final model = await rwkv.getModelBaseInfo(state.modelInstanceId);
    MessageModel assistant = MessageModel.create(
      role: rwkv.roleAssistant,
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

    await _sendInternal(rwkv, history, assistant, convId);
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

  Future send(RwkvInterface rwkv) async {
    final text = state.inputController.text.trim();
    if (text.isEmpty) {
      return;
    }

    String convId = state.selected.id;

    // Send event is triggered by keyboard event,
    // so we need to clear input after sending
    Future.delayed(const Duration(milliseconds: 50), () {
      state.inputController.clear();
    });
    final model = await rwkv.getModelBaseInfo(state.modelInstanceId);
    final message = MessageModel.create(
      role: rwkv.roleUser,
      convId: convId,
      text: text,
      modelName: model.name,
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
      role: rwkv.roleAssistant,
      convId: convId,
      reasoning: state.generationConfig.reasoningEffort,
      modelName: model.name,
    );

    await _sendInternal(rwkv, history, assistant, convId);
  }

  Future _sendInternal(
    RwkvInterface rwkv,
    List<MessageModel> history,
    MessageModel assistant,
    String convId,
  ) async {
    final messages = history
        .map((e) => ChatMessage(role: e.role, content: e.text))
        .toList();
    if (assistant.text.isNotEmpty) {
      messages.add(ChatMessage(role: assistant.role, content: assistant.text));
    }
    if (assistant.text.startsWith('<') &&
        !assistant.text.contains('</think>')) {
      assistant = assistant.copyWith(thinkEndAt: assistant.text.length);
    }
    final conv = state.conversations.firstWhere((e) => e.id == convId);
    final systemPrompt = conv.useGlobalSystemPrompt ? null : conv.systemPrompt;

    assistant = assistant.copyWith(stopReason: StopReason.none);
    final stream = rwkv.chat(
      messages,
      state.modelInstanceId,
      conv.decodeParamId,
      state.generationConfig.copyWith(prompt: systemPrompt),
    );
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
      await for (final resp in stream) {
        if (isClosed) {
          return;
        }
        _onGenerateResponse(
          conversationId: convId,
          history: history,
          resp: resp,
        );
      }
      _onGenerateDone(conversationId: convId, history: history);
    } catch (e, s) {
      _onGenerateError(conversationId: convId, history: history, e: e);
      throw AppException('generate error', cause: e, stackTrace: s);
    } finally {
      // support rwkv only for now
      final isRwkv = state.modelState.isRWKV;
      if (!isClosed && isRwkv) {
        var assistant = state.messages[convId]!.last;
        try {
          final count = RwkvTokenizer.default_.tokenCount(assistant.text);
          assistant = assistant.copyWithExtra(tokenCount: count);
        } catch (e) {
          logw(assistant.text);
          loge(e);
        }
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
  }

  void _onGenerateResponse({
    required String conversationId,
    required List<MessageModel> history,
    required GenerationResponse resp,
  }) {
    var assistant = state.messages[conversationId]!.last;
    final thinkResolved =
        assistant.thinkEndAt == -1 ||
        assistant.thinkEndAt < assistant.text.length;
    int? thinkEndAt;
    String content = (assistant.text + resp.text).trimLeft();

    /// NOTE: correct model output from rwkv_lightning
    if (assistant.reasoningEnabled && content.startsWith('>')) {
      content = "<think$content";
    }

    if (!thinkResolved) {
      if (!content.startsWith('<')) {
        thinkEndAt = -1;
        logd('think resolved, no think tag');
      } else {
        final index = content.indexOf('</think>');
        thinkEndAt = content.length;
        if (index != -1) {
          thinkEndAt = index;
          logd('think resolved: $thinkEndAt');
          assistant = assistant.copyWithExtra(
            thinkEndTime: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
    }

    if (assistant.firstTokenTime <= 0) {
      assistant = assistant.copyWithExtra(
        firstTokenTime: DateTime.now().millisecondsSinceEpoch,
      );
    }
    assistant = assistant.copyWith(
      text: content,
      stopReason: resp.stopReason,
      thinkEndAt: thinkEndAt,
    );
    assistant = assistant.copyWithExtra(tokenCount: resp.tokenCount);
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

  void _onGenerateDone({
    required String conversationId,
    required List<MessageModel> history,
  }) {
    var assistant = state.messages[conversationId]!.last;
    updateConversation(
      conversationId,
      (c) => c.copyWith(updateAt: DateTime.now()),
    );
    var ns = state.copyWith(generating: false);
    if (assistant.stopReason == StopReason.none) {
      assistant = assistant.copyWith(stopReason: StopReason.unknown);
    }
    if (assistant.thinkEndTime <= 0) {
      assistant = assistant.copyWithExtra(
        thinkEndTime: DateTime.now().millisecondsSinceEpoch,
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
    var assistant = state.messages[conversationId]!.last;
    assistant = assistant.copyWith(updateAt: DateTime.now());
    if (isCanceledException(e)) {
      assistant = assistant.copyWith(stopReason: StopReason.canceled);
    } else {
      assistant = assistant.copyWith(error: "$e", stopReason: StopReason.error);
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
}
