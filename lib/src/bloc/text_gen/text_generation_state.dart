part of 'text_generation_cubit.dart';

class TextGenerationState {
  final TextEditingController controllerText;
  final ScrollController controllerScroll;
  final bool autoScrolling;
  final bool generating;
  final bool showSettingPane;
  final String decodeParamId;
  final ModelLoadState modelState;

  String get modelInstanceId => modelState.instanceId;

  TextGenerationState({
    required this.controllerText,
    required this.controllerScroll,
    required this.generating,
    required this.autoScrolling,
    required this.decodeParamId,
    required this.showSettingPane,
    required this.modelState,
  });

  factory TextGenerationState.initial() {
    return TextGenerationState(
      controllerScroll: ScrollController(),
      controllerText: TextEditingController(),
      decodeParamId: '',
      generating: false,
      autoScrolling: true,
      showSettingPane: false,
      modelState: ModelLoadState.empty(),
    );
  }

  TextGenerationState copyWith({
    TextEditingController? controllerText,
    ScrollController? controllerScroll,
    bool? generating,
    bool? autoScrolling,
    String? decodeParamId,
    bool? showSettingPane,
    ModelLoadState? modelState,
  }) {
    return TextGenerationState(
      controllerText: controllerText ?? this.controllerText,
      generating: generating ?? this.generating,
      controllerScroll: controllerScroll ?? this.controllerScroll,
      autoScrolling: autoScrolling ?? this.autoScrolling,
      decodeParamId: decodeParamId ?? this.decodeParamId,
      showSettingPane: showSettingPane ?? this.showSettingPane,
      modelState: modelState ?? this.modelState,
    );
  }
}
