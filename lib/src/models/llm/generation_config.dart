import 'package:rwkv_dart/rwkv_dart.dart';

class GenerationConfig {
  final List<int>? stopTokens;
  final ReasoningEffort reasoningEffort;
  final String prompt;

  const GenerationConfig({
    this.stopTokens,
    this.reasoningEffort = .none,
    this.prompt = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'stop_tokens': stopTokens,
      'reasoning_effort': reasoningEffort.name,
      'prompt': prompt,
    };
  }

  static GenerationConfig fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      stopTokens: json['stop_tokens'] as List<int>?,
      reasoningEffort:
          ReasoningEffort.fromName(json['reasoning_effort']) ?? .none,
      prompt: json['prompt'] as String? ?? '',
    );
  }

  GenerationConfig copyWith({
    List<int>? stopTokens,
    ReasoningEffort? reasoningEffort,
    String? prompt,
  }) {
    return GenerationConfig(
      stopTokens: stopTokens ?? this.stopTokens,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      prompt: prompt ?? this.prompt,
    );
  }
}
