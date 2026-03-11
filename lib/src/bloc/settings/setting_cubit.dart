import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';
import 'package:rwkv_studio/src/repository/setting_repository.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

export 'package:rwkv_studio/src/models/settings/settings_models.dart';

part 'setting_state.dart';

extension SettingStateExtension on BuildContext {
  SettingCubit get settings => BlocProvider.of<SettingCubit>(this);
}

class SettingCubit extends Cubit<SettingState> {
  final SettingRepository _repository;

  SettingCubit(this._repository) : super(SettingState.initial()) {
    /// skip initialize state
    stream.distinct((p, c) => p == c).skip(1).listen((e) {
      _persist();
    });
  }

  List<RemoteServiceModel> getEnabledRemoteServices() {
    return state.model.remoteServices.where((e) => e.enabled).toList();
  }

  Future<void> reset() async {
    final settings = await _repository.reset();
    emit(SettingState.fromSettings(settings, initialized: state.initialized));
  }

  Future init() async {
    try {
      final settings = await _repository.load();
      if (settings != null) {
        /// Wait for the first frame instead of adding a fixed startup delay.
        await WidgetsBinding.instance.endOfFrame;
        emit(SettingState.fromSettings(settings, initialized: true));
      }
    } catch (e, s) {
      loge(e, s);
    }

    emit(state.copyWith(initialized: true));
  }

  void setAppearance(AppearanceSettingsModel appearance) {
    emit(state.copyWith(appearance: appearance));
  }

  void setServiceSetting(ModelSettingsModel model) {
    emit(state.copyWith(model: model));
  }

  void setPythonSetting(PythonSettingsModel python) {
    emit(state.copyWith(python: python));
  }

  Future setCacheSetting(CacheSettingsModel cache) async {
    final validated = await _repository.validateCacheSetting(
      cache,
      fallback: state.cache,
    );
    emit(state.copyWith(cache: validated));
  }

  void _persist() async {
    await _repository.save(state.settings);
    logi('settings persisted');
  }
}
