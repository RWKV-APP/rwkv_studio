import 'package:rwkv_dart/rwkv_dart.dart';

class ToolCallInfo {
  final String toolName;
  final String type;
  final Map<String, String> arguments;
  final Map<String, dynamic> result;
  final bool completed;

  ToolCallInfo._({
    required this.toolName,
    required this.type,
    required this.arguments,
    required this.result,
    required this.completed,
  });

  factory ToolCallInfo.fromCall(ToolCall toolCall) {
    return ToolCallInfo._(
      toolName: toolCall.function?.name ?? '-',
      type: toolCall.type ?? '-',
      arguments: {'args': toolCall.function?.arguments ?? ''},
      result: {},
      completed: false,
    );
  }

  ToolCallInfo copyWithResult(McpToolCallResult result) {
    return ToolCallInfo._(
      toolName: toolName,
      type: type,
      arguments: arguments,
      result: {'message': result.messageContent, 'raw': result.result?.raw},
      completed: true,
    );
  }

  static ToolCallInfo fromMap(dynamic map) {
    return ToolCallInfo._(
      toolName: map['tool_name'] ?? '-',
      type: map['type'] ?? '',
      arguments: Map<String, String>.from(map['arguments'] ?? {}),
      result: Map<String, dynamic>.from(map['result'] ?? {}),
      completed: map['completed'] ?? false,
    );
  }

  Map toMap() {
    return {
      'tool_name': toolName,
      'type': type,
      'arguments': arguments,
      'result': result,
      'completed': completed,
    };
  }
}
