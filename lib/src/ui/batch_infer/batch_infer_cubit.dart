import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_interface.dart';
import 'package:rxdart/rxdart.dart';

part 'batch_infer_state.dart';

class BatchInferCubit extends Cubit<BatchInferState> {
  StreamSubscription? _subscription;

  BatchInferCubit() : super(BatchInferState.empty());

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

  Future submit() async {
    _subscription = _startBatchInfer()
        .throttleTime(const Duration(milliseconds: 60))
        .listen(
          (cells) {
            emit(state.copyWith(cells: cells.toList(), isRunning: true));
          },
          onDone: () {
            emit(state.copyWith(isRunning: false));
          },
          onError: (e) {
            emit(state.copyWith(isRunning: false));
          },
        );
  }

  Stream<List<String>> _startBatchInfer() async* {
    final size = state.setting;
    List<String> cells = [for (var i = 0; i < size.size; i++) ''];
    int len = 1000;
    if (size.size > 600) {
      len = 50;
    } else if (size.size > 100) {
      len = 100;
    } else if (size.size >= 64) {
      len = 500;
    }
    int index = 0;
    String str = '';
    final rnd = Random();
    for (var i = 0; i < 500; i++) {
      for (var r = 0; r < size.row; r++) {
        for (var c = 0; c < size.col; c++) {
          index = r * size.col + c;
          str = cells[index];
          if (str.length > (len + 40)) {
            str = str.substring(str.length - len);
          }
          cells[index] = str + String.fromCharCode(47 + rnd.nextInt(80));
        }
      }
      if (isClosed) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 30));
      yield cells;
    }
  }
}
