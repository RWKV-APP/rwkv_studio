import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/cache/preferences_box.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/utils/equatable.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

part 'appearance_state.dart';

part 'cache_setting_state.dart';

part 'python_setting_state.dart';

part 'service_setting_state.dart';

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

  List<RemoteService> getEnabledRemoteServices() {
    return state.model.remoteServices.where((e) => e.enabled).toList();
  }

  void reset() {
    emit(SettingState.initial());
  }

  Future init() async {
    try {
      emit(state.copyWith(model: ModelSettingState.default_));
      final ns = await PreferencesBox.getRaw();
      if (ns != null) {
        /// avoid theme apply not work
        await Future.delayed(const Duration(milliseconds: 500));
        emit(ns);
      }
      _checkCacheDirAvailable(state.cache);
    } catch (e, s) {
      loge(e, s);
    }
  }

  void setAppearance(AppearanceSettingState appearance) {
    emit(state.copyWith(appearance: appearance));
  }

  void setServiceSetting(ModelSettingState model) {
    emit(state.copyWith(model: model));
  }

  void setPythonSetting(PythonSettingState python) {
    emit(state.copyWith(python: python));
  }

  Future setCacheSetting(CacheSettingState cache) async {
    await _checkCacheDirAvailable(cache);
  }

  void _persist() async {
    await PreferencesBox.putRaw(state);
    logi('settings persisted');
  }

  Future _checkCacheDirAvailable(CacheSettingState cache, [
    CacheSettingState? reset,
  ]) async {
    final initial = reset ?? CacheSettingState.initial();
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
