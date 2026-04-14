import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';

sealed class ChatEvent extends Equatable {
  final DateTime createdAt;

  ChatEvent({DateTime? createdAt}) : createdAt = createdAt ?? DateTime.now();

  @override
  List<Object?> get props => [createdAt];
}

final class ChatAssistantEvent extends ChatEvent {
  final String reasoningDelta;
  final String contentDelta;
  final StopReason stopReason;
  final int tokenCount;
  final int? round;

  ChatAssistantEvent({
    this.reasoningDelta = '',
    this.contentDelta = '',
    required this.stopReason,
    this.tokenCount = -1,
    this.round,
  });

  bool get hasReasoningDelta => reasoningDelta.isNotEmpty;

  bool get hasContentDelta => contentDelta.isNotEmpty;

  bool get hasDelta => hasReasoningDelta || hasContentDelta;

  @override
  List<Object?> get props => [
    ...super.props,
    reasoningDelta,
    contentDelta,
    stopReason,
    tokenCount,
    round,
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
  final int? round;
  final StopReason stopReason;

  ChatCompletedEvent({required this.text, this.round, super.createdAt, required this.stopReason});

  @override
  List<Object?> get props => [...super.props, text, round, stopReason];
}

final class ChatFailedEvent extends ChatEvent {
  final String error;

  ChatFailedEvent({required this.error, super.createdAt});

  @override
  List<Object?> get props => [...super.props, error];
}
