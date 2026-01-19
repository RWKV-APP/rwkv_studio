import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/utils/subscription_mixin.dart';

part 'text_generation_state.dart';

extension Ext on BuildContext {
  TextGenerationCubit get textGen => BlocProvider.of<TextGenerationCubit>(this);
}

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

  void onModelReleased() {
    emit(state.copyWith(modelState: ModelLoadState.empty()));
  }

  void resetSettings() {
    emit(state.copyWith(decodeParam: DecodeParam.initial()));
  }

  void toggleSettingPane() {
    emit(state.copyWith(showSettingPane: !state.showSettingPane));
  }

  void setDecodeParam(DecodeParam param) {
    emit(state.copyWith(decodeParam: param));
  }

  void loadModel(RwkvInterface rwkv, ModelInfo model) {
    final sp = rwkv
        .loadOrGetModelInstance(model)
        .listen(
          (e) {
            emit(state.copyWith(modelState: e));
          },
          onError: (e, s) {
            emit(state.copyWith(modelState: ModelLoadState.error(model.id, e)));
          },
        );
    addSubscription(sp);
  }

  Future generate(RwkvInterface rwkv) async {
    final prompt = state.controllerText.text.trim();
    emit(state.copyWith(generating: true));

    String result = state.controllerText.text;

    final sp = rwkv
        .generate(prompt, state.modelInstanceId, state.decodeParam)
        .listen(
          (e) {
            result += e.text;
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
