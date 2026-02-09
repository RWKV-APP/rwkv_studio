import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'app_state.dart';

extension Ext on BuildContext {
  AppCubit get app => read<AppCubit>();
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppState.initial());

  void init({required String selectedPythonId, required String albatrossPath}) {
    emit(
      state.copyWith(
        albatrossPath: albatrossPath,
        selectedPythonId: selectedPythonId,
      ),
    );
  }

  void setPane(int pane) {
    emit(state.copyWith(pane: pane));
  }

  Future<List<Python>> detectPythonInterpreters() async {
    final python = await Python.findPythons();
    final conda = await Python.detectCondaEnv();
    emit(
      state.copyWith(
        pythons: [
          for (final e in python) Python.fromPath(e),
          for (final e in conda) Python.fromCondaEnv(e),
        ],
      ),
    );
    return state.pythons;
  }

  Python? getSelectedPython() {
    return state.pythons
        .where((e) => e.id == state.selectedPythonId)
        .firstOrNull;
  }

  void onPythonSelected({required String id, String? albatrossPath}) {
    logd('on python interpreter selected: $id');
    emit(state.copyWith(selectedPythonId: id, albatrossPath: albatrossPath));
  }

  void jump2ModelManage() {
    emit(state.copyWith(pane: 2));
  }
}
