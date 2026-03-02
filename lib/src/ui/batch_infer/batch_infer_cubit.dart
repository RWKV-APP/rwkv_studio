import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/rwkv_tokenizer.dart';
import 'package:rwkv_studio/src/utils/stream_speed_sampler.dart';
import 'package:rxdart/rxdart.dart';

part 'batch_infer_state.dart';

class BatchInferCubit extends Cubit<BatchInferState> {
  StreamSubscription? _subscription;

  StreamController<String> _speedSampler = StreamController<String>();

  BatchInferCubit() : super(BatchInferState.empty());

  static BatchInferCubit of(BuildContext context) =>
      BlocProvider.of<BatchInferCubit>(context);

  Future loadModel(
    BuildContext context,
    RwkvInterface rwkv,
    ModelInfo model,
  ) async {
    await for (var s in rwkv.loadOrGetModelInstance(context, model)) {
      emit(state.copyWith(modelState: s));
    }
  }

  void toggleShowSettingPanel() {
    emit(state.copyWith(showSettingPanel: !state.showSettingPanel));
  }

  void setDecodeParamId(String paramId) {
    emit(state.copyWith(decodeParamId: paramId));
  }

  void setBatchSize(BatchSizeState size) {
    emit(
      state.copyWith(
        setting: size,
        cells: [for (var i = 0; i < size.size; i++) '-'],
      ),
    );
  }

  Future stop() async {
    _subscription?.cancel();
    _speedSampler.close();
    emit(state.copyWith(isRunning: false));
  }

  Future submit(RwkvInterface rwkv) async {
    _speedSampler.close();
    _speedSampler = StreamController<String>();
    _speedSampler.stream
        .transform(
          StreamSpeedSampler.createTransformer(
            window: const Duration(seconds: 5),
            maxSampleRate: const Duration(milliseconds: 500),
            enableSmoothing: true,
            smoothingAlpha: 0.5,
            counter: (v) => RwkvTokenizer.tokenCountEstimate(v),
          ),
        )
        .listen((v) {
          emit(state.copyWith(performance: PerformanceState(tps: v.speed)));
        });

    _subscription?.cancel();
    emit(state.copyWith(isRunning: true));
    Stream<List<String>> stream = _startBatchInfer(rwkv);

    if (state.setting.size > 200) {
      stream = stream.asyncExpand((e) async* {
        yield [for (final c in e) c.length > 14 ? c.substring(0, 14) : c];
        await Future.delayed(const Duration(milliseconds: 500));
        yield [
          for (final c in e) c.length > 14 ? c.substring(c.length - 14) : c,
        ];
      });
    }

    _subscription = stream
        .throttleTime(const Duration(milliseconds: 60))
        .listen(
          (cells) {
            emit(state.copyWith(cells: cells.toList(), isRunning: true));
          },
          onDone: () {
            logd('batch infer done');
            _speedSampler.close();
            emit(state.copyWith(isRunning: false));
          },
          onError: (e, s) {
            logd('batch infer error: $e, $s');
            _speedSampler.close();
            emit(state.copyWith(isRunning: false));
          },
        );
  }

  Stream<List<String>> _startBatchInfer(RwkvInterface rwkv) async* {
    final size = state.setting;
    List<String> cells = [for (var i = 0; i < size.size; i++) ''];
    int len;
    if (size.size > 600) {
      len = 50;
    } else if (size.size > 100) {
      len = 100;
    } else if (size.size >= 64) {
      len = 500;
    } else {
      len = 1000;
    }
    final prompt = state.textController.text.trim();

    final stream = rwkv.generate(
      prompt,
      state.modelState.instanceId,
      state.decodeParamId,
      batch: size.size,
    );

    String str = '';
    await for (var res in stream) {
      for (final (index, choice) in res.choices!.indexed) {
        str = cells[index];
        if (str.length > (len + 40)) {
          str = str.substring(str.length - len);
        }
        if (!_speedSampler.isClosed) {
          _speedSampler.add(choice);
        }
        cells[index] = str + choice;
      }
      if (isClosed || state.isRunning == false) {
        return;
      }
      yield cells;
    }
  }
}
