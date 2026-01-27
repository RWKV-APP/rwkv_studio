import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/subscription_mixin.dart';

part 'chat_state.dart';

extension Ext on BuildContext {
  ChatCubit get chat => read<ChatCubit>();
}

class ChatCubit extends Cubit<ChatState> with SubscriptionManagerMixin {
  ChatCubit() : super(ChatState.empty());

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

  void resetSettings() {
    emit(state.copyWith(decodeParam: DecodeParam.initial()));
  }

  void setDecodeParam(DecodeParam param) {
    emit(state.copyWith(decodeParam: param));
  }

  void toggleThinkMode() {
    emit(
      state.copyWith(
        generationConfig: state.generationConfig.copyWith(
          chatReasoning: !state.generationConfig.chatReasoning,
        ),
      ),
    );
  }

  Future newChat() async {
    final conv = ConversationState(
      id: DateTime.now().toString(),
      title: 'New Chat',
      updateAt: DateTime.now(),
    );
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
    await Future.delayed(Duration(milliseconds: 100));
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
    final message = MessageState.create(
      role: rwkv.roleUser,
      text: text,
      modelName: await rwkv.getModelName(state.modelInstanceId),
    );

    String convId = state.selected.id;
    state.inputController.clear();
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
    emit(state.copyWith(generating: true));
    bool thinkResolved = assistant.thinkEndAt < assistant.text.length;
    if (assistant.text.isNotEmpty && !assistant.text.startsWith('<')) {
      thinkResolved = true;
      assistant = assistant.copyWith(thinkEndAt: assistant.text.length);
    }
    rwkv
        .chat(
          messages,
          state.modelInstanceId,
          state.decodeParam,
          state.generationConfig,
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
                }
              }
            }
            assistant = assistant.copyWith(
              text: content,
              stopReason: resp.stopReason,
              thinkEndAt: thinkEndAt,
            );
            emit(
              state.copyWith(
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
            emit(state.copyWith(generating: false));
          },
          onError: (e, s) {
            assistant = assistant.copyWith(error: e.toString());
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
