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
import 'package:rwkv_studio/src/bloc/llm/llm_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/repository/mcp_repository.dart';
import 'package:rwkv_studio/src/repository/remote_service_repository.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:window_manager/window_manager.dart';

class AppStateCoordinator {
  final AppCubit app;
  final ChatCubit chat;
  final ModelManageCubit modelManage;
  final LlmCubit llm;
  final SettingCubit setting;
  final TextGenerationCubit textGen;
  final RemoteServiceRepository remoteServiceRepository;
  final McpRepository mcpRepository;
  bool _initializing = false;
  bool _initialized = false;
  SettingState? _lastSettingState;
  Future<void>? _remoteServiceBootstrap;
  Future<void>? _mcpBootstrap;
  StreamSubscription<RemoteServiceSnapshot>? _remoteServiceSubscription;

  AppStateCoordinator({
    required this.app,
    required this.chat,
    required this.modelManage,
    required this.llm,
    required this.setting,
    required this.textGen,
    required this.remoteServiceRepository,
    required this.mcpRepository,
  });

  factory AppStateCoordinator.fromContext(BuildContext context) {
    return AppStateCoordinator(
      app: context.read<AppCubit>(),
      chat: context.read<ChatCubit>(),
      modelManage: context.read<ModelManageCubit>(),
      llm: context.read<LlmCubit>(),
      setting: context.read<SettingCubit>(),
      textGen: context.read<TextGenerationCubit>(),
      remoteServiceRepository: context.read<RemoteServiceRepository>(),
      mcpRepository: context.read<McpRepository>(),
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
        _runStep('llm.init', llm.init),
        _runStep('chat.init', chat.init),
        _runStep('modelManage.init', modelManage.init),
      ]);
      _bindRemoteServiceSync();
      await _syncInitialSettings(setting.state);
      onLlmStateChanged(llm.state);
      _initialized = true;

      _restoreConversationSelectedModelOnInitialized();
      modelManage.ensureRuntimeReady();
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
      await _runStep('apply appearance', () async {
        onAppearanceChanged(state.appearance);
      });
    }
    if (previous.appearance.userType != state.appearance.userType) {
      await _runStep('apply user type', () async {
        onUserTypeChanged(state.appearance.userType);
      });
    }
    if (previous.model.remoteServices != state.model.remoteServices) {
      await _runStep('sync remote services', () async {
        await onRemoteServicesChanged(state.model.remoteServices);
      });
    }
    if (previous.mcp != state.mcp) {
      await _runStep('sync MCP services', () async {
        await onMcpSettingsChanged(state.mcp);
      });
    }
    if (previous.python != state.python) {
      await _runStep('apply python', () async {
        onPythonChanged(state.python);
      });
    }
    if (previous.model.modelListUrl != state.model.modelListUrl) {
      await _runStep('apply model list url', () async {
        await onModelListUrlChanged(state.model.modelListUrl);
      });
    }
    if (!kIsWeb && previous.model.modelServer != state.model.modelServer) {
      await _runStep('apply model server', () async {
        onModelServerChanged(state.model.modelServer);
      });
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
    _bootstrapMcpSettings(state.mcp);
    if (!kIsWeb) {
      await _runStep('apply model server', () async {
        onModelServerChanged(state.model.modelServer);
      });
    }
  }

  void _bootstrapRemoteServices(List<RemoteServiceModel> remoteServices) {
    _remoteServiceBootstrap ??=
        _runStep(
          'sync remote services',
          () => onRemoteServicesChanged(remoteServices),
        ).whenComplete(() {
          _remoteServiceBootstrap = null;
        });
    unawaited(_remoteServiceBootstrap);
  }

  void _bootstrapMcpSettings(McpSettingsModel mcp) {
    _mcpBootstrap ??=
        _runStep(
          'sync MCP services',
          () => onMcpSettingsChanged(mcp),
        ).whenComplete(() {
          _mcpBootstrap = null;
        });
    unawaited(_mcpBootstrap);
  }

  Future<void> _runStep(String label, Future<void> Function() action) async {
    try {
      await action();
      logd('AppStateCoordinator $label succeeded');
    } catch (e, s) {
      final error = AppException.wrap(e, s);
      loge('AppStateCoordinator $label failed', error, error.stackTrace ?? s);
    }
  }

  void _bindRemoteServiceSync() {
    if (_remoteServiceSubscription != null) {
      return;
    }
    _remoteServiceSubscription = remoteServiceRepository.watchSnapshot().listen(
      (snapshot) {
        llm.syncRemoteServiceInstances(snapshot.services);
      },
    );
    llm.syncRemoteServiceInstances(remoteServiceRepository.snapshot.services);
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

  Future<void> onMcpSettingsChanged(McpSettingsModel mcp) async {
    logd('mcp-settings updated: ${mcp.servers.length} servers');
    await mcpRepository.syncConnections(mcp.servers);
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
      _syncModelServerInstances(modelServer: modelServer, state: llm.state);
    }

    app.onModelServerSettingChanged(modelServer);
  }

  void onLlmStateChanged(LlmState state) {
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
    required LlmState state,
  }) {
    final models = modelServer.onlyLocalModel
        ? state.localInstances
        : state.models.values;
    app.onModelInstanceListChanged(models);
  }

  void _restoreConversationSelectedModelOnInitialized() async {
    await chat.initialized();
    final modelId = chat.state.selected.modelId;
    if (modelId.isEmpty) {
      return;
    }

    //
    llm.stream
        .distinct((prev, next) => prev.models == next.models)
        .mapNotNull((e) {
          return e.models.values
              .where((inst) => inst.info.id == modelId)
              .firstOrNull;
        })
        .first
        .timeout(const Duration(seconds: 10))
        .then((e) {
          chat.selectConversation(chat.state.selected);
        })
        .catchError((e) {
          logw(
            'restore conv model failed: await for model $modelId initialize timed out',
          );
        });
  }

  Future<void> dispose() async {
    await _remoteServiceSubscription?.cancel();
    _remoteServiceSubscription = null;
  }
}
