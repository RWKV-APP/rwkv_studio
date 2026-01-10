import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/utils/subscription_mixin.dart';

class TextGenerationState {
  final TextEditingController controllerText;
  final ScrollController controllerScroll;
  final String modelInstanceId;
  final bool autoScrolling;
  final bool generating;

  TextGenerationState({
    required this.controllerText,
    required this.controllerScroll,
    required this.modelInstanceId,
    required this.generating,
    required this.autoScrolling,
  });

  factory TextGenerationState.initial() {
    return TextGenerationState(
      controllerScroll: ScrollController(),
      controllerText: TextEditingController(),
      modelInstanceId: '',
      generating: false,
      autoScrolling: true,
    );
  }

  TextGenerationState copyWith({
    TextEditingController? controllerText,
    ScrollController? controllerScroll,
    String? modelInstanceId,
    bool? generating,
    bool? autoScrolling,
  }) {
    return TextGenerationState(
      controllerText: controllerText ?? this.controllerText,
      modelInstanceId: modelInstanceId ?? this.modelInstanceId,
      generating: generating ?? this.generating,
      controllerScroll: controllerScroll ?? this.controllerScroll,
      autoScrolling: autoScrolling ?? this.autoScrolling,
    );
  }
}

typedef GenerateFunc =
    Stream<String> Function(String prompt, String modelInstanceId);

class TextGenerationCubit extends Cubit<TextGenerationState>
    with SubscriptionManagerMixin {
  TextGenerationCubit() : super(TextGenerationState.initial()) {
    state.controllerText.addListener(() {
      if (state.generating && state.autoScrolling) {
        final scrollOffset = state.controllerScroll.position.maxScrollExtent;
        state.controllerScroll.jumpTo(scrollOffset);
      }
    });
  }

  void selectModel(String modelInstanceId) {
    emit(state.copyWith(modelInstanceId: modelInstanceId));
  }

  void generate(GenerateFunc func) {
    final prompt = state.controllerText.text.trim();
    emit(state.copyWith(generating: true));

    String result = state.controllerText.text;

    final sp = func(prompt, state.modelInstanceId).listen(
      (e) {
        result += e;
        state.controllerText.text = result.substring(prompt.length);
      },
      onError: (e) {
        emit(state.copyWith(generating: false));
      },
      onDone: () {
        emit(state.copyWith(generating: false));
      },
    );
    addSubscription(sp);
  }
}
