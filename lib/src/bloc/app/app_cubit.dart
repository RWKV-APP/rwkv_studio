import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/python/interpreter.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

part 'app_state.dart';

extension Ext on BuildContext {
  AppCubit get app => read<AppCubit>();
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppState.initial());

  void init({required SettingState settings}) {
    final albatrossPath = settings.python.albatrossPath;
    final selectedPythonId = settings.python.selected;

    final userType = settings.appearance.userType;
    emit(
      state.copyWith(
        navBarItems: userType == UserType.developer
            ? NavBarItem.devNavItems()
            : NavBarItem.defaultNavItems(),
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

  void onUserTypeChanged(UserType userType) {
    final navItems = userType == UserType.developer
        ? NavBarItem.devNavItems()
        : NavBarItem.defaultNavItems();
    final expand = navItems.flatten(
      (e) => <NavBarItem>[e, ...(e.subitems ?? [])],
    );
    emit(state.copyWith(navBarItems: navItems, pane: expand.length - 1));
  }

  void onPythonSelected({required String id, String? albatrossPath}) {
    logd('on python interpreter selected: $id');
    emit(state.copyWith(selectedPythonId: id, albatrossPath: albatrossPath));
  }

  void setShowNavBar(bool show) {
    emit(state.copyWith(showNavBar: show));
  }

  void toggleFullScreen() async {
    final fullScreen = !state.fullScreen;
    if (!kIsWeb) {
      if (fullScreen) {
        await Window.enterFullscreen();
        Window.removeToolbar();
      } else {
        await Window.exitFullscreen();
        Window.addToolbar();
      }
    }
    emit(state.copyWith(fullScreen: fullScreen, showNavBar: !fullScreen));
  }

  void jump2ModelManage() {
    emit(state.copyWith(pane: 2));
  }

  void jump2PythonSettings() {
    emit(state.copyWith(pane: 5));
  }
}
