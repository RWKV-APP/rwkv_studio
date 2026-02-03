part of 'chat_cubit.dart';

extension MessageExtras on MessageState {
  int get firstTokenTime => extra['first_token_time'] ?? 0;

  set firstTokenTime(int value) => extra['first_token_time'] = value;

  int get thinkEndTime => extra['think_end_time'] ?? 0;

  set thinkEndTime(int value) => extra['think_end_time'] = value;
}

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

  bool get stopped => stopReason != StopReason.none;

  bool get isUser => role == 'user';

  bool get hasThinkContent => thinkEndAt > 8;

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
      extra: {},
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
