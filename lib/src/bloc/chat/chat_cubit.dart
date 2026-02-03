import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/errors/assert.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/subscription_mixin.dart';

part 'chat_state.dart';

part 'conversation_state.dart';

part 'message_state.dart';

extension Ext on BuildContext {
  ChatCubit get chat => read<ChatCubit>();
}

class ChatCubit extends Cubit<ChatState> with SubscriptionManagerMixin {
  ChatCubit() : super(ChatState.empty());

  Future init() async {
    if (state.initialized) {
      return;
    }

    if (state.messages.isEmpty) {
      await newChat();
    }
    emit(state.copyWith(initialized: true));
  }

  void onModelReleased() {
    emit(state.copyWith(modelState: ModelLoadState.empty()));
  }

  Future loadModel(RwkvInterface rwkv, ModelInfo model) async {
    final sp = rwkv
        .loadOrGetModelInstance(model)
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

  Future newChat() async {
    final conv = ConversationState.create();
    emit(
      state.copyWith(
        conversations: [conv, ...state.conversations],
        selected: conv,
      ),
    );
  }

  void selectConversation(ConversationState conv) {
    emit(state.copyWith(selected: conv));
  }

  Future deleteConversation(String id) async {
    ConversationState selected = state.selected;
    List<ConversationState> conversations = state.conversations
        .where((e) => e.id != id)
        .toList();
    Map<String, List<MessageState>> messages = state.messages;
    if (selected.id == id) {
      selected = conversations.firstOrNull ?? ConversationState.empty;
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
    final convId = state.selected.id;

    final history = state.messages[convId]!;
    history.removeAt(history.length - 1);

    MessageState generated = MessageState.create(
      role: rwkv.roleAssistant,
      modelName: await rwkv.getModelName(state.modelInstanceId),
    );

    emit(
      state.copyWith(
        messages: {
          ...state.messages,
          convId: [...history, generated],
        },
      ),
    );

    await _sendInternal(rwkv, history, generated, convId);
  }

  void updateConversation(
    String id,
    ConversationState Function(ConversationState) update,
  ) {
    ConversationState? updated;
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
    final message = MessageState.create(
      role: rwkv.roleUser,
      text: text,
      modelName: await rwkv.getModelName(state.modelInstanceId),
    );
    final history = <MessageState>[...(state.messages[convId] ?? []), message];

    if (history.length == 1) {
      updateConversation(
        convId,
        (c) => c.copyWith(title: text, updateAt: DateTime.now()),
      );
    }
    emit(state.copyWith(messages: {...state.messages, convId: history}));

    MessageState assistant = MessageState.create(
      role: rwkv.roleAssistant,
      modelName: await rwkv.getModelName(state.modelInstanceId),
    );

    await _sendInternal(rwkv, history, assistant, convId);
  }

  Future _sendInternal(
    RwkvInterface rwkv,
    List<MessageState> history,
    MessageState assistant,
    String conversationId,
  ) async {
    final messages = history.map((e) => e.text).toList();
    if (assistant.text.isNotEmpty) {
      messages.add(assistant.text);
    }
    bool thinkResolved = assistant.thinkEndAt < assistant.text.length;
    if (assistant.text.isNotEmpty && !assistant.text.startsWith('<')) {
      thinkResolved = true;
      assistant = assistant.copyWith(thinkEndAt: assistant.text.length);
    }
    final conv = state.conversations.firstWhere((e) => e.id == conversationId);
    final systemPrompt = conv.useGlobalSystemPrompt ? null : conv.systemPrompt;

    assistant = assistant.copyWith(stopReason: StopReason.none);
    emit(
      state.copyWith(
        generating: true,
        messages: {
          ...state.messages,
          conversationId: [...history, assistant],
        },
      ),
    );
    rwkv
        .chat(
          messages,
          state.modelInstanceId,
          conv.decodeParmaId,
          state.generationConfig.copyWith(prompt: systemPrompt),
        )
        .listen(
          (resp) {
            int? thinkEndAt;
            final content = (assistant.text + resp.text).trimLeft();
            if (!thinkResolved) {
              if (!content.startsWith('<')) {
                thinkEndAt = 0;
                thinkResolved = true;
                logd('think resolved, no think tag');
              } else {
                final index = content.indexOf('</think>');
                thinkEndAt = content.length;
                if (index != -1) {
                  thinkEndAt = index;
                  thinkResolved = true;
                  logd('think resolved: $thinkEndAt');
                  assistant.thinkEndTime =
                      DateTime.now().millisecondsSinceEpoch;
                }
              }
            }

            if (assistant.firstTokenTime <= 0) {
              assistant.firstTokenTime = DateTime.now().millisecondsSinceEpoch;
            }
            assistant = assistant.copyWith(
              text: content,
              stopReason: resp.stopReason,
              thinkEndAt: thinkEndAt,
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
          },
          onDone: () {
            updateConversation(
              conversationId,
              (c) => c.copyWith(updateAt: DateTime.now()),
            );
            var ns = state.copyWith(generating: false);
            if (assistant.stopReason == StopReason.none) {
              assistant = assistant.copyWith(stopReason: StopReason.unknown);
              if (assistant.thinkEndTime <= 0) {
                assistant.thinkEndTime = DateTime.now().millisecondsSinceEpoch;
              }
              ns = ns.copyWith(
                messages: {
                  ...state.messages,
                  conversationId: [...history, assistant],
                },
              );
            }
            logd('chat generation done: ${assistant.stopReason}');
            emit(ns);
          },
          onError: (e, s) {
            if (isCanceledException(e)) {
              assistant = assistant.copyWith(stopReason: StopReason.canceled);
            } else {
              loge(e, s);
              assistant = assistant.copyWith(
                error: "$e",
                stopReason: StopReason.error,
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
          },
        );
  }
}
