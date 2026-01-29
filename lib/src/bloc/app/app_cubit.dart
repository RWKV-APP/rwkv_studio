import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_state.dart';

extension Ext on BuildContext {
  AppCubit get app => read<AppCubit>();
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(AppState.initial());

  void setPane(int pane) {
    emit(state.copyWith(pane: pane));
  }

  void jump2ModelManage() {
    emit(state.copyWith(pane: 8));
  }
}
