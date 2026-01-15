part of 'text_generation_cubit.dart';

class TextGenerationState {
  final TextEditingController controllerText;
  final ScrollController controllerScroll;
  final String modelInstanceId;
  final bool autoScrolling;
  final bool generating;
  final bool showSettingPane;
  final DecodeParam decodeParam;

  TextGenerationState({
    required this.controllerText,
    required this.controllerScroll,
    required this.modelInstanceId,
    required this.generating,
    required this.autoScrolling,
    required this.decodeParam,
    required this.showSettingPane,
  });

  factory TextGenerationState.initial() {
    return TextGenerationState(
      controllerScroll: ScrollController(),
      controllerText: TextEditingController(),
      decodeParam: DecodeParam.initial(),
      modelInstanceId: '',
      generating: false,
      autoScrolling: true,
      showSettingPane: false,
    );
  }

  TextGenerationState copyWith({
    TextEditingController? controllerText,
    ScrollController? controllerScroll,
    String? modelInstanceId,
    bool? generating,
    bool? autoScrolling,
    DecodeParam? decodeParam,
    bool? showSettingPane,
  }) {
    return TextGenerationState(
      controllerText: controllerText ?? this.controllerText,
      modelInstanceId: modelInstanceId ?? this.modelInstanceId,
      generating: generating ?? this.generating,
      controllerScroll: controllerScroll ?? this.controllerScroll,
      autoScrolling: autoScrolling ?? this.autoScrolling,
      decodeParam: decodeParam ?? this.decodeParam,
      showSettingPane: showSettingPane ?? this.showSettingPane,
    );
  }
}
