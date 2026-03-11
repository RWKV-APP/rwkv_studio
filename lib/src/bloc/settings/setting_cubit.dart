import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/cache/preferences_box.dart';
import 'package:rwkv_studio/src/models/settings/settings_models.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

export 'package:rwkv_studio/src/models/settings/settings_models.dart';

part 'setting_state.dart';

extension SettingStateExtension on BuildContext {
  SettingCubit get settings => BlocProvider.of<SettingCubit>(this);
}

class SettingCubit extends Cubit<SettingState> {
  SettingCubit() : super(SettingState.initial()) {
    /// skip initialize state
    stream.distinct((p, c) => p == c).skip(1).listen((e) {
      _persist();
    });
  }

  List<RemoteServiceModel> getEnabledRemoteServices() {
    return state.model.remoteServices.where((e) => e.enabled).toList();
  }

  void reset() {
    emit(SettingState.initial());
  }

  Future init() async {
    try {
      final settings = await PreferencesBox.getRaw();
      if (settings != null) {
        /// avoid theme apply not work
        await Future.delayed(const Duration(milliseconds: 500));
        emit(SettingState.fromSettings(settings, initialized: true));
      }
      _checkCacheDirAvailable(state.cache);
    } catch (e, s) {
      loge(e, s);
    }

    if (state.model.modelListUrl.isEmpty) {
      emit(state.copyWith(model: ModelSettingsModel.default_));
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
    await _checkCacheDirAvailable(cache);
  }

  void _persist() async {
    await PreferencesBox.putRaw(state.settings);
    logi('settings persisted');
  }

  Future _checkCacheDirAvailable(
    CacheSettingsModel cache, [
    CacheSettingsModel? reset,
  ]) async {
    if (kIsWeb) {
      return;
    }
    final initial = reset ?? CacheSettingsModel.initial();
    String? modelDir;
    String? cacheDir;

    try {
      Directory dir = Directory(cache.modelDownloadDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      if (modelDir != initial.modelDownloadDir) {
        modelDir = dir.path;
      }
    } catch (e) {
      loge(e);
      logw('model dir is not available, reset to ${initial.modelDownloadDir}');
      modelDir = initial.modelDownloadDir;
    }
    try {
      Directory dir = Directory(state.cache.appCacheDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      if (cacheDir != initial.appCacheDir) {
        cacheDir = dir.path;
      }
    } catch (e) {
      loge(e);
      logw('cache dir is not available, reset to ${initial.appCacheDir}');
    }

    if (modelDir == null && cacheDir == null) {
      return;
    }
    emit(
      state.copyWith(
        cache: state.cache.copyWith(
          modelDownloadDir: modelDir,
          appCacheDir: cacheDir,
        ),
      ),
    );
  }
}
