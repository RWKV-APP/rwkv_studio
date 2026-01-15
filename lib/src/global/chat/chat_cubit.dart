import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/rwkv/rwkv.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'chat_state.dart';

extension Ext on BuildContext {
  ChatCubit get chat => read<ChatCubit>();
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit() : super(ChatState.empty());

  void onModelSelected(String modelInstanceId) {
    emit(state.copyWith(modelInstanceId: modelInstanceId));
  }

  void toggleThinkMode() {
    emit(state.copyWith());
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
        selected: conv.id,
      ),
    );
  }

  void selectConversation(String id) {
    emit(state.copyWith(selected: id));
  }

  Future deleteConversation(String id) async {
    String selected = state.selected;
    List<ConversationState> conversations = state.conversations
        .where((e) => e.id != id)
        .toList();
    Map<String, List<MessageState>> messages = state.messages;
    if (selected == id) {
      selected = conversations.firstOrNull?.id ?? '';
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

  Future pause(RwkvInterface rwkv) async {
    await rwkv.stop(state.modelInstanceId);
    emit(state.copyWith(generating: false));
    await Future.delayed(Duration(milliseconds: 100));
    final history = state.messages[state.selected] ?? [];
    final last = history.last;
    emit(
      state.copyWith(
        messages: {
          ...state.messages,
          state.selected: [
            ...history.take(history.length - 1),
            last.copyWith(stopReason: StopReason.canceled),
          ],
        },
      ),
    );
  }

  Future resume(RwkvInterface rwkv) async {
    final history = state.messages[state.selected]!;
    final generated = history.removeLast();
    await _sendInternal(rwkv, history, generated);
  }

  Future regenerate(RwkvInterface rwkv) async {
    final history = state.messages[state.selected]!;
    history.removeAt(history.length - 1);

    MessageState generated = MessageState(
      id: DateTime.now().toString(),
      text: '',
      datetime: DateTime.now(),
      role: 'assistant',
      modelName: rwkv.getModelName(state.modelInstanceId),
    );

    emit(
      state.copyWith(
        messages: {
          ...state.messages,
          state.selected: [...history, generated],
        },
      ),
    );

    await _sendInternal(rwkv, history, generated);
  }

  Future send(RwkvInterface rwkv) async {
    final text = state.inputController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final message = MessageState(
      id: DateTime.now().toString(),
      text: text,
      datetime: DateTime.now(),
      role: 'user',
      modelName: rwkv.getModelName(state.modelInstanceId),
    );
    state.inputController.clear();
    final history = <MessageState>[
      ...(state.messages[state.selected] ?? []),
      message,
    ];

    List<ConversationState>? conversations = history.length > 1
        ? null
        : state.conversations.map((e) {
            return e.id == state.selected ? e.copyWith(title: text) : e;
          }).toList();
    emit(
      state.copyWith(
        conversations: conversations,
        messages: {...state.messages, state.selected: history},
      ),
    );

    MessageState assistant = MessageState(
      id: DateTime.now().toString(),
      text: '',
      datetime: DateTime.now(),
      role: 'assistant',
      modelName: rwkv.getModelName(state.modelInstanceId),
    );

    await _sendInternal(rwkv, history, assistant);
  }

  Future _sendInternal(
    RwkvInterface rwkv,
    List<MessageState> history,
    MessageState assistant,
  ) async {
    final messages = history.map((e) => e.text).toList();
    if (assistant.text.isNotEmpty) {
      messages.add(assistant.text);
    }
    emit(state.copyWith(generating: true));
    rwkv
        .chat(messages, state.modelInstanceId, state.decodeParam)
        .listen(
          (resp) {
            assistant = assistant.copyWith(
              text: assistant.text + resp.text,
              stopReason: resp.stopReason,
            );
            emit(
              state.copyWith(
                messages: {
                  ...state.messages,
                  state.selected: [...history, assistant],
                },
              ),
            );
          },
          onDone: () {
            emit(state.copyWith(generating: false));
          },
          onError: (e, s) {
            assistant = assistant.copyWith(error: e.toString());
            emit(
              state.copyWith(
                generating: false,
                messages: {
                  ...state.messages,
                  state.selected: [...history, assistant],
                },
              ),
            );
          },
        );
  }
}
