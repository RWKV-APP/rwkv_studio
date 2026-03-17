import 'package:rwkv_dart/rwkv_dart.dart';

class GenerationConfig {
  final List<int>? stopTokens;
  final ReasoningEffort reasoningEffort;
  final String prompt;
  final bool enableMcp;

  const GenerationConfig({
    this.stopTokens,
    this.reasoningEffort = .none,
    this.prompt = '',
    this.enableMcp = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'stop_tokens': stopTokens,
      'reasoning_effort': reasoningEffort.name,
      'prompt': prompt,
      'enable_mcp': enableMcp,
    };
  }

  static GenerationConfig fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      stopTokens: json['stop_tokens'] as List<int>?,
      reasoningEffort:
          ReasoningEffort.fromName(json['reasoning_effort']) ?? .none,
      prompt: json['prompt'] as String? ?? '',
      enableMcp: json['enable_mcp'] as bool? ?? false,
    );
  }

  GenerationConfig copyWith({
    List<int>? stopTokens,
    ReasoningEffort? reasoningEffort,
    String? prompt,
    bool? enableMcp,
  }) {
    return GenerationConfig(
      stopTokens: stopTokens ?? this.stopTokens,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      prompt: prompt ?? this.prompt,
      enableMcp: enableMcp ?? this.enableMcp,
    );
  }
}
