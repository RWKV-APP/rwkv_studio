import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

class AppStateCoordinator {
  final AppCubit app;
  final ChatCubit chat;
  final ModelManageCubit modelManage;
  final RwkvCubit rwkv;
  final SettingCubit setting;
  final TextGenerationCubit textGen;
  bool _initializing = false;
  bool _initialized = false;
  SettingState? _lastSettingState;
  Future<void>? _remoteServiceBootstrap;

  AppStateCoordinator({
    required this.app,
    required this.chat,
    required this.modelManage,
    required this.rwkv,
    required this.setting,
    required this.textGen,
  });

  factory AppStateCoordinator.fromContext(BuildContext context) {
    return AppStateCoordinator(
      app: context.read<AppCubit>(),
      chat: context.read<ChatCubit>(),
      modelManage: context.read<ModelManageCubit>(),
      rwkv: context.read<RwkvCubit>(),
      setting: context.read<SettingCubit>(),
      textGen: context.read<TextGenerationCubit>(),
    );
  }

  Future<void> initialize() async {
    if (_initialized || _initializing) {
      return;
    }
    _initializing = true;

    try {
      await _runStep('app.init', app.init);
      await Future.wait([
        _runStep('setting.init', setting.init),
        _runStep('rwkv.init', rwkv.init),
        _runStep('chat.init', chat.init),
        _runStep('modelManage.init', modelManage.init),
      ]);
      await _syncInitialSettings(setting.state);
      onRwkvStateChanged(rwkv.state);
      _initialized = true;
    } finally {
      _initializing = false;
    }
  }

  Future<void> onSettingStateChanged(SettingState state) async {
    if (_initializing || !state.initialized) {
      return;
    }

    final previous = _lastSettingState;
    _lastSettingState = state;

    if (previous == null) {
      await _syncInitialSettings(state);
      return;
    }

    if (previous.appearance.theme.brightness !=
        state.appearance.theme.brightness) {
      onAppearanceChanged(state.appearance);
    }
    if (previous.appearance.userType != state.appearance.userType) {
      onUserTypeChanged(state.appearance.userType);
    }
    if (previous.model.remoteServices != state.model.remoteServices) {
      await onRemoteServicesChanged(state.model.remoteServices);
    }
    if (previous.python != state.python) {
      onPythonChanged(state.python);
    }
    if (previous.model.modelListUrl != state.model.modelListUrl) {
      await onModelListUrlChanged(state.model.modelListUrl);
    }
    if (!kIsWeb && previous.model.modelServer != state.model.modelServer) {
      onModelServerChanged(state.model.modelServer);
    }
  }

  Future<void> _syncInitialSettings(SettingState state) async {
    _lastSettingState = state;

    await _runStep('apply appearance', () async {
      syncAppearance(state.appearance);
    });
    await _runStep('apply user type', () async {
      onUserTypeChanged(state.appearance.userType);
    });
    await _runStep('apply python', () async {
      onPythonChanged(state.python);
    });
    await _runStep('configure model manager runtime', () async {
      modelManage.setRuntimeConfig(
        modelDownloadDir: state.cache.modelDownloadDir,
        configProviderUrl: state.model.modelListUrl,
      );
    });
    _bootstrapRemoteServices(state.model.remoteServices);
    if (!kIsWeb) {
      await _runStep('apply model server', () async {
        onModelServerChanged(state.model.modelServer);
      });
    }
  }

  void _bootstrapRemoteServices(List<RemoteServiceModel> remoteServices) {
    _remoteServiceBootstrap ??= _runStep(
      'sync remote services',
      () => onRemoteServicesChanged(remoteServices),
    ).whenComplete(() {
      _remoteServiceBootstrap = null;
    });
    unawaited(_remoteServiceBootstrap);
  }

  Future<void> _runStep(
    String label,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e, s) {
      loge('AppStateCoordinator $label failed: $e', s);
    }
  }

  void syncAppearance(AppearanceSettingsModel appearance) {
    if (kIsWeb) {
      return;
    }
    final isLight = appearance.theme == AppearanceSettingsModel.lightTheme;

    if (!Platform.isMacOS) {
      if (isLight) {
        WindowManager.instance.setBrightness(Brightness.light);
      } else {
        WindowManager.instance.setBrightness(Brightness.dark);
      }
      Window.setEffect(effect: WindowEffect.mica, dark: !isLight);
    } else {
      Window.setEffect(effect: WindowEffect.hudWindow, dark: !isLight);
      Window.overrideMacOSBrightness(dark: !isLight);
      Window.setWindowBackgroundColorToClear();
    }
  }

  void onAppearanceChanged(AppearanceSettingsModel appearance) {
    logd('appearance updated: ${appearance.theme.brightness}');
    syncAppearance(appearance);
  }

  void onUserTypeChanged(UserType userType) {
    logd('user-type updated: $userType');
    app.onUserTypeChanged(userType);
  }

  Future<void> onRemoteServicesChanged(
    List<RemoteServiceModel> remoteServices,
  ) async {
    logd('model-service-settings updated: ${remoteServices.length} services');
    await app.updateModelServices(remoteServices);
  }

  void onPythonChanged(PythonSettingsModel python) {
    logd('python updated: ${python.selected}');
    app.onPythonSelected(
      id: python.selected,
      albatrossPath: python.albatrossPath,
    );
  }

  Future<void> onModelListUrlChanged(String url) async {
    logd('model-list-url updated: $url');
    await modelManage.updateModelConfigUrl(url);
  }

  void onModelServerChanged(ModelServerSettingsModel modelServer) {
    logd('model-server setting updated: ${modelServer.toMap()}');

    if (!kIsWeb && modelServer.enabled) {
      _syncModelServerInstances(modelServer: modelServer, state: rwkv.state);
    }

    app.onModelServerSettingChanged(modelServer);
  }

  void onRwkvStateChanged(RwkvState state) {
    logd('model-instance updated: ${state.models.length} instances');

    if (!kIsWeb) {
      _syncModelServerInstances(
        modelServer: setting.state.model.modelServer,
        state: state,
      );
    }

    final chatInstanceId = chat.state.modelInstanceId;
    final textGenInstanceId = textGen.state.modelInstanceId;
    if (chatInstanceId.isNotEmpty && state.models[chatInstanceId] == null) {
      chat.onModelReleased();
    }
    if (textGenInstanceId.isNotEmpty &&
        state.models[textGenInstanceId] == null) {
      textGen.onModelReleased();
    }
  }

  void _syncModelServerInstances({
    required ModelServerSettingsModel modelServer,
    required RwkvState state,
  }) {
    final models = modelServer.onlyLocalModel
        ? state.localInstances
        : state.models.values;
    app.onModelInstanceListChanged(models);
  }
}
