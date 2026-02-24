part of 'chat_cubit.dart';

extension MessageExtras on MessageState {
  int get firstTokenTime => extra['first_token_time'] ?? 0;

  set firstTokenTime(int value) => extra['first_token_time'] = value;

  int get thinkEndTime => extra['think_end_time'] ?? 0;

  set thinkEndTime(int value) => extra['think_end_time'] = value;
}

class MessageState {
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
  final Map<String, dynamic> extra;

  bool get stopped => stopReason != StopReason.none;

  bool get paused => stopReason == StopReason.canceled;

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
    if (thinkEndAt <= 0) {
      return text;
    }
    return text.substring(thinkEndAt).replaceAll('</think>', '').trim();
  }

  MessageState._({
    required this.id,
    required this.convId,
    required this.text,
    required this.updateAt,
    required this.role,
    required this.modelName,
    required this.createAt,
    this.thinkEndAt = 0,
    this.stopReason = StopReason.none,
    this.error = '',
    this.extra = const {},
  });

  static int _incrementalId = 0;

  static String _newId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  factory MessageState.create({
    required final String role,
    required final String convId,
    String? text,
    String? modelName,
  }) {
    final id = _newId();
    return MessageState._(
      createAt: DateTime.now(),
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

  MessageState copyWith({
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
  }) {
    return MessageState._(
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
    );
  }
}
