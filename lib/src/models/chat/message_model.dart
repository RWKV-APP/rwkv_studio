import 'package:rwkv_dart/rwkv_dart.dart';

import 'message_content.dart';

class MessageModel {
  final String id;
  final String convId;
  final String role;
  final StopReason stopReason;
  final List<MessageContent> contents;
  final DateTime createAt;
  final DateTime updateAt;
  final String error;
  final String modelName;
  final ReasoningEffort reasoning;
  final Map<String, dynamic> extra;

  bool get showProgress =>
      !stopped && (role == 'assistant' && contents.isEmpty);

  bool get isUser => role == 'user';

  bool get stopped => stopReason != StopReason.none;

  String copyClipboardText() {
    return contents.map((e) => e.text).join('\n');
  }

  String editeText() {
    return contents.where((e) => e.isTextContent).lastOrNull?.text ?? '';
  }

  const MessageModel._({
    required this.id,
    required this.convId,
    required this.updateAt,
    required this.role,
    required this.modelName,
    required this.createAt,
    required this.reasoning,
    this.contents = const [],
    this.stopReason = StopReason.none,
    this.error = '',
    this.extra = const {},
  });

  static int _incrementalId = 0;

  static String _newId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  factory MessageModel.create({
    required String role,
    required String convId,
    List<MessageContent> contents = const [],
    String? modelName,
    ReasoningEffort? reasoning,
  }) {
    final id = _newId();
    return MessageModel._(
      createAt: DateTime.now(),
      reasoning: reasoning ?? ReasoningEffort.none,
      id: '$convId-$id-${_incrementalId++}',
      convId: convId,
      updateAt: DateTime.now(),
      role: role,
      stopReason: StopReason.none,
      error: '',
      extra: const {},
      modelName: modelName ?? '',
      contents: contents,
    );
  }

  MessageModel copyWithEditContent({required String content}) {
    if (contents.isEmpty) return this;
    if (isUser) {
      return copyWith(
        contents: [
          ...contents.map(
            (e) => e.isTextContent ? e.copyWith(data: content) : e,
          ),
        ],
      );
    } else {
      if (stopped && contents.last.isTextContent) {
        final n = contents.toList();
        n.last = n.last.copyWith(data: content);
        return copyWith(contents: n);
      } else {
        return this;
      }
    }
  }

  MessageModel copyWith({
    String? id,
    String? convId,
    DateTime? createAt,
    DateTime? updateAt,
    String? role,
    String? error,
    String? modelName,
    StopReason? stopReason,
    Map<String, dynamic>? extra,
    ReasoningEffort? reasoning,
    List<MessageContent>? contents,
  }) {
    return MessageModel._(
      id: id ?? this.id,
      createAt: createAt ?? this.createAt,
      convId: convId ?? this.convId,
      updateAt: updateAt ?? this.updateAt,
      role: role ?? this.role,
      error: error ?? this.error,
      modelName: modelName ?? this.modelName,
      stopReason: stopReason ?? this.stopReason,
      extra: extra ?? this.extra,
      reasoning: reasoning ?? this.reasoning,
      contents: contents ?? this.contents,
    );
  }

  ChatMessage toChatMessage() {
    if (role.toLowerCase() == 'user') {
      return ChatMessage(role: role, content: contents.first.text);
    }
    if (role.toLowerCase() == 'assistant') {
      final answer = contents.where((e) => e.type == .answer).firstOrNull;

      return ChatMessage(
        role: role,
        content: answer?.text ?? '',
        toolCallId: '',
        toolCalls: [
          //
        ],
      );
    }
    return ChatMessage(role: role, content: '');
  }
}

extension MessageModelExtras on MessageModel {
  int get tokenCount => extra['token_count'] ?? -1;

  MessageModel copyWithTokenCount(int? tokenCount) {
    return copyWith(
      extra: {...extra, 'token_count': tokenCount ?? this.tokenCount},
    );
  }
}
