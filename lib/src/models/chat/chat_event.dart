import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

sealed class ChatEvent extends Equatable {
  final DateTime createdAt;

  ChatEvent({DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  @override
  List<Object?> get props => [createdAt];
}

final class ChatAssistantEvent extends ChatEvent {
  final String deltaMessage;
  final StopReason stopReason;
  final int tokenCount;

  ChatAssistantEvent({
    required this.deltaMessage,
    required this.stopReason,
    this.tokenCount = -1,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    deltaMessage,
    stopReason,
    tokenCount,
  ];
}

final class ChatToolCallEvent extends ChatEvent {
  final int round;
  final ToolCall toolCall;

  ChatToolCallEvent({
    required this.round,
    required this.toolCall,
    super.createdAt,
  });

  @override
  List<Object?> get props => [...super.props, round, toolCall];
}

final class ChatToolResultEvent extends ChatEvent {
  final int round;
  final McpToolCallResult result;

  ChatToolResultEvent({
    required this.round,
    required this.result,
    super.createdAt,
  });

  @override
  List<Object?> get props => [...super.props, round, result];
}

final class ChatCompletedEvent extends ChatEvent {
  final String text;

  ChatCompletedEvent({required this.text, super.createdAt});

  @override
  List<Object?> get props => [...super.props, text];
}

final class ChatFailedEvent extends ChatEvent {
  final String error;

  ChatFailedEvent({required this.error, super.createdAt});

  @override
  List<Object?> get props => [...super.props, error];
}
