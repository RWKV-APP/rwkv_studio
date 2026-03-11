import 'package:rwkv_dart/rwkv_dart.dart';

extension MessageModelExtras on MessageModel {
  int get firstTokenTime => extra['first_token_time'] ?? 0;

  int get thinkEndTime => extra['think_end_time'] ?? 0;

  int get tokenCount => extra['token_count'] ?? -1;

  MessageModel copyWithExtra({
    int? firstTokenTime,
    int? thinkEndTime,
    int? tokenCount,
  }) {
    return copyWith(
      extra: {
        'first_token_time': firstTokenTime ?? this.firstTokenTime,
        'think_end_time': thinkEndTime ?? this.thinkEndTime,
        'token_count': tokenCount ?? this.tokenCount,
      },
    );
  }
}

class MessageModel {
  final String id;
  final String convId;
  final String text;
  final int thinkEndAt;
  final DateTime createAt;
  final DateTime updateAt;
  final String role;
  final String error;
  final String modelName;
  final StopReason stopReason;
  final ReasoningEffort reasoning;
  final Map<String, dynamic> extra;

  bool get stopped => stopReason != StopReason.none;

  bool get paused => stopReason == StopReason.canceled;

  bool get isUser => role == 'user';

  bool get hasThinkContent => thinkEndAt > 8;

  bool get reasoningEnabled => reasoning != ReasoningEffort.none;

  bool get thinking =>
      thinkEndAt == text.length && stopReason == StopReason.none;

  String get thinkContent {
    return text
        .substring(0, thinkEndAt)
        .replaceFirst('<think>', '')
        .replaceFirst('<think', '')
        .trim();
  }

  String get bodyContent {
    if (thinkEndAt <= 0) {
      return text;
    }
    return text.substring(thinkEndAt).replaceAll('</think>', '').trim();
  }

  MessageModel._({
    required this.id,
    required this.convId,
    required this.text,
    required this.updateAt,
    required this.role,
    required this.modelName,
    required this.createAt,
    required this.reasoning,
    this.thinkEndAt = 0,
    this.stopReason = StopReason.none,
    this.error = '',
    this.extra = const {},
  });

  static int _incrementalId = 0;

  static String _newId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  factory MessageModel.create({
    required final String role,
    required final String convId,
    String? text,
    String? modelName,
    ReasoningEffort? reasoning,
  }) {
    final id = _newId();
    return MessageModel._(
      createAt: DateTime.now(),
      reasoning: reasoning ?? ReasoningEffort.none,
      id: '$convId-$id-${_incrementalId++}',
      convId: convId,
      text: text ?? '',
      updateAt: DateTime.now(),
      role: role,
      stopReason: StopReason.none,
      error: '',
      extra: {},
      modelName: modelName ?? '',
    );
  }

  MessageModel copyWith({
    String? id,
    String? convId,
    String? text,
    DateTime? createAt,
    DateTime? updateAt,
    String? role,
    String? error,
    String? modelName,
    StopReason? stopReason,
    Map<String, dynamic>? extra,
    int? thinkEndAt,
    ReasoningEffort? reasoning,
  }) {
    return MessageModel._(
      id: id ?? this.id,
      createAt: createAt ?? this.createAt,
      convId: convId ?? this.convId,
      text: text ?? this.text,
      updateAt: updateAt ?? this.updateAt,
      role: role ?? this.role,
      error: error ?? this.error,
      modelName: modelName ?? this.modelName,
      stopReason: stopReason ?? this.stopReason,
      extra: extra ?? this.extra,
      thinkEndAt: thinkEndAt ?? this.thinkEndAt,
      reasoning: reasoning ?? this.reasoning,
    );
  }
}
