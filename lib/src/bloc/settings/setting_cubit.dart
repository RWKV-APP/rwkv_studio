import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'setting_state.dart';

extension SettingStateExtension on BuildContext {
  SettingCubit get settings => BlocProvider.of<SettingCubit>(this);
}

class SettingCubit extends Cubit<SettingState> {
  SettingCubit() : super(SettingState.initial());

  void setAppearance(AppearanceSettingState appearance) {
    emit(state.copyWith(appearance: appearance));
  }

  void setRemoteServiceList(List<RemoteService> services) {
    emit(state.copyWith(remoteServices: services));
  }
}
