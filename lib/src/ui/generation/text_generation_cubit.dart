import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/utils/subscription_mixin.dart';

part 'text_generation_state.dart';

typedef GenerateFunc =
    Stream<String> Function(
      String prompt,
      String modelInstanceId,
      DecodeParam decodeParam,
      int maxTokens,
    );

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

  void resetSettings() {
    emit(state.copyWith(decodeParam: DecodeParam.initial(), maxTokens: 2000));
  }

  void setMaxTokens(int maxTokens) {
    emit(state.copyWith(maxTokens: maxTokens));
  }

  void toggleSettingPane() {
    emit(state.copyWith(showSettingPane: !state.showSettingPane));
  }

  void setDecodeParam(DecodeParam param) {
    emit(state.copyWith(decodeParam: param));
  }

  void selectModel(String modelInstanceId) {
    emit(state.copyWith(modelInstanceId: modelInstanceId));
  }

  void generate(GenerateFunc func) {
    final prompt = state.controllerText.text.trim();
    emit(state.copyWith(generating: true));

    String result = state.controllerText.text;

    final sp =
        func(
          prompt,
          state.modelInstanceId,
          state.decodeParam,
          state.maxTokens,
        ).listen(
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
