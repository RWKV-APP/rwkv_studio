import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
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

  void loadModel(BuildContext context, RwkvInterface rwkv, ModelInfo model) {
    final sp = rwkv
        .loadOrGetModelInstance(context, model)
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

  void stop(RwkvInterface rwkv) {
    rwkv.stop(state.modelInstanceId);
    emit(state.copyWith(generating: false));
  }

  Future generate(RwkvInterface rwkv, {bool fim = false}) async {
    final prompt = state.controllerText.text.trim();
    String result = '';

    String prefix = '';
    String suffix = '';
    int offset = 0;
    if (fim) {
      offset = state.controllerText.selection.baseOffset;
      if (offset == prompt.length) {
        throw const AppException('fim suffix is empty');
      }
      if (offset == 0) {
        throw const AppException('fim prefix is empty');
      }
      prefix = prompt.substring(0, offset);
      suffix = prompt.substring(offset);
      result = '';
    }
    final stream = rwkv.generate(
      prompt,
      state.modelInstanceId,
      state.decodeParamId,
      fimSuffix: fim ? suffix : null,
    );
    try {
      await for (final e in stream) {
        if (isClosed) {
          return;
        }
        if (fim) {
          result += e.text;
          final r = prefix + result + suffix;
          state.controllerText.text = r;
        } else {
          result += e.text;
          if (!result.startsWith(prompt)) {
            result = prompt + result;
          }
          state.controllerText.text = result;
        }
        if (!state.generating) {
          emit(state.copyWith(generating: true));
        }
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        logd('generate canceled');
        return;
      }
      throw AppException('generate error', cause: e);
    } finally {
      if (!isClosed) {
        emit(state.copyWith(generating: false));
      }
    }
  }
}
