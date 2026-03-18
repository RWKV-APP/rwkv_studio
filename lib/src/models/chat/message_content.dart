import 'package:rwkv_dart/rwkv_dart.dart';

enum ContentType {
  unknown(0),
  think(1),
  toolCall(2),
  answer(3),
  question(4),
  error(5);

  final int id;

  const ContentType(this.id);

  static ContentType fromId(int id) =>
      ContentType.values.firstWhere((e) => e.id == id);
}

class ToolCallInfo {
  final ToolCall tool;
  final McpToolResult? result;

  const ToolCallInfo({required this.tool, required this.result});

  Map<String, dynamic> toJson() => {
    'tool': tool.toJson(),
    'result': result?.raw,
  };

  factory ToolCallInfo.fromJson(Map<String, dynamic> json) {
    return ToolCallInfo(
      tool: ToolCall.fromJson(json['tool']),
      result: json['result'] != null
          ? McpToolResult(content: [], isError: false, raw: json['result'])
          : null,
    );
  }
}

class MessageContent {
  final ContentType type;
  final dynamic data;
  final int? round;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool completed;

  ToolCall get tool => (data as ToolCallInfo).tool;

  McpToolResult? get toolCallResult => (data as ToolCallInfo).result;

  Duration get duration =>
      updatedAt != null ? updatedAt!.difference(createdAt) : .zero;

  bool get showDisplay {
    if (type == .think && text.trim() == '') {
      return false;
    }
    return true;
  }

  String get text {
    if (data is String) {
      return data as String;
    }
    if (data is Map) {
      return data['text']?.toString() ?? '';
    }
    return data?.toString() ?? '';
  }

  bool get isTextContent =>
      type == .question || type == .think || type == .answer;

  Map<String, dynamic> get mapData {
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data as Map<String, dynamic>);
    }
    if (data is Map) {
      return (data as Map).map((key, value) => MapEntry('$key', value));
    }
    return {'text': text};
  }

  MessageContent._(
    this.type,
    this.data, {
    this.round,
    this.completed = false,
    this.updatedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       assert(type != .toolCall || data is ToolCallInfo),
       assert(type != .think || data is String);

  factory MessageContent.question(
    String text, {
    int? round,
    bool completed = true,
  }) => MessageContent._(
    ContentType.question,
    text,
    round: round,
    completed: completed,
  );

  factory MessageContent.think(
    String text, {
    int? round,
    bool completed = false,
  }) => MessageContent._(
    ContentType.think,
    _trimToTextDisplay(text),
    round: round,
    completed: completed,
  );

  factory MessageContent.error(dynamic error) =>
      MessageContent._(.error, error);

  factory MessageContent.unknown(dynamic data) =>
      MessageContent._(.unknown, data);

  factory MessageContent.toolCall(
    ToolCallInfo data, {
    int? round,
    bool completed = true,
  }) => MessageContent._(.toolCall, data, round: round, completed: completed);

  factory MessageContent.answer(
    String text, {
    int? round,
    bool completed = false,
  }) => MessageContent._(
    .answer,
    _trimToTextDisplay(text),
    round: round,
    completed: completed,
  );

  MessageContent copyWith({
    ContentType? type,
    dynamic data,
    int? round,
    bool? completed,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return MessageContent._(
      type ?? this.type,
      data ?? this.data,
      round: round ?? this.round,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MessageContent.fromMap(Map<String, dynamic> map) {
    final updatedAt = _asInt(map['updated_at']);
    final createdAt = _asInt(map['created_at']) ?? 0;
    final type = ContentType.fromId(
      _asInt(map['type']) ?? ContentType.answer.id,
    );

    dynamic data = map['data'];

    if (type == ContentType.toolCall) {
      // data = ToolCallInfo.fromJson(data);
    }
    return MessageContent._(
      type,
      data,
      round: _asInt(map['round']),
      completed: map.containsKey('completed')
          ? map['completed'] == true
          : type != ContentType.think,
      updatedAt: updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAt),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.id,
      'data': _searchableData(),
      if (round != null) 'round': round,
      'completed': completed,
      if (updatedAt != null) 'updated_at': updatedAt!.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  Map _searchableData() {
    if (type == ContentType.toolCall) {
      return (data as ToolCallInfo).toJson();
    }
    return {'text': data};
  }
}

String _trimToTextDisplay(String text) {
  if (text.startsWith('<think>')) {
    return text.replaceFirst('<think>', '');
  }
  if (text.startsWith('</think>')) {
    return text.replaceFirst('</think>', '');
  } else if (text.endsWith('</think>')) {
    return text.substring(0, text.length - 7);
  } else if (text.startsWith('<tool_call>')) {
    return text.replaceFirst('<tool_call>', '');
  } else if (text.endsWith('</tool_call>')) {
    return text.substring(0, text.length - 13);
  }
  return text;
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}
