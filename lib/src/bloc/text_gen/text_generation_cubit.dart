import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/llm/llm_interface.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/errors/assert.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
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

  void toggleSettingPane() {
    emit(state.copyWith(showSettingPane: !state.showSettingPane));
  }

  void setDecodeParamId(String paramId) {
    emit(state.copyWith(decodeParamId: paramId));
  }

  void loadModel(BuildContext context, LlmInterface llm, ModelInfo model) {
    final sp = llm
        .loadModel(model)
        .listen(
          (e) {
            emit(state.copyWith(modelState: e));
          },
          onError: (e, s) {
            emit(
              state.copyWith(
                modelState: ModelLoadState.error(
                  model.id,
                  AppException.wrap(e, s),
                ),
              ),
            );
          },
        );
    addSubscription(sp);
  }

  void stop(LlmInterface llm) {
    llm.stop(state.modelInstanceId);
    emit(state.copyWith(generating: false));
  }

  Future generate(LlmInterface llm, {bool fim = false}) async {
    final prompt = state.controllerText.text.trim();
    String result = '';

    String prefix = '';
    String suffix = '';
    int offset = 0;
    if (fim) {
      offset = state.controllerText.selection.baseOffset;
      if (offset == prompt.length) {
        throw const AppException.validation('FIM suffix is empty');
      }
      if (offset == 0) {
        throw const AppException.validation('FIM prefix is empty');
      }
      prefix = prompt.substring(0, offset);
      suffix = prompt.substring(offset);
      result = '';
    }
    final stream = llm.generate(
      fim ? prefix : prompt,
      state.modelInstanceId,
      state.decodeParamId,
      fimSuffix: fim ? suffix : null,
    );
    try {
      emit(state.copyWith(generating: true));
      await for (final e in stream) {
        if (isClosed) {
          return;
        }
        if (fim) {
          result += e.content;
          final r = prefix + result + suffix;
          state.controllerText.text = r;
        } else {
          result += e.content;
          if (!result.startsWith(prompt)) {
            result = prompt + result;
          }
          state.controllerText.text = result;
        }
        if (!state.generating) {
          emit(state.copyWith(generating: true));
        }
      }
    } catch (e, s) {
      if (isCanceledException(e)) {
        logd('generate canceled');
        return;
      }
      Error.throwWithStackTrace(AppException.wrap(e, s), s);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(generating: false));
      }
    }
  }
}
