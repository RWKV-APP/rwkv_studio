import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

part 'batch_infer_state.dart';

class BatchInferCubit extends Cubit<BatchInferState> {
  StreamSubscription? _subscription;

  final StreamController<String> _speedSampler = StreamController<String>();

  BatchInferCubit() : super(BatchInferState.empty()) {
    _speedSampler
        .stream //
        .where((v) => v.isNotEmpty)
        .windowTime(const Duration(milliseconds: 1000))
        .listen((v) {
          //
        });
  }

  Future loadModel(
    BuildContext context,
    RwkvInterface rwkv,
    ModelInfo model,
  ) async {
    await for (var s in rwkv.loadOrGetModelInstance(context, model)) {
      emit(state.copyWith(modelState: s));
    }
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
    emit(state.copyWith(isRunning: false));
  }

  Future submit(RwkvInterface rwkv) async {
    _subscription?.cancel();
    emit(state.copyWith(isRunning: true));
    _subscription = _startBatchInfer(rwkv)
        .throttleTime(const Duration(milliseconds: 60))
        .listen(
          (cells) {
            emit(state.copyWith(cells: cells.toList(), isRunning: true));
          },
          onDone: () {
            logd('batch infer done');
            emit(state.copyWith(isRunning: false));
          },
          onError: (e) {
            logd('batch infer error: $e');
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
      DecodeParam.initial(),
      batch: size.size,
    );

    String str = '';
    await for (var res in stream) {
      for (final (index, choice) in res.choices!.indexed) {
        str = cells[index];
        if (str.length > (len + 40)) {
          str = str.substring(str.length - len);
        }
        _speedSampler.add(choice);
        cells[index] = str + choice;
      }
      if (isClosed || state.isRunning == false) {
        return;
      }
      yield cells;
    }
  }
}
