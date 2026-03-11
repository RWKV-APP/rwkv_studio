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
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:window_manager/window_manager.dart';

class WithGlobalStateSync extends StatefulWidget {
  final Widget child;

  const WithGlobalStateSync({super.key, required this.child});

  @override
  State<WithGlobalStateSync> createState() => _WithGlobalStateSyncState();
}

class _WithGlobalStateSyncState extends State<WithGlobalStateSync> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _init();
      } catch (e, s) {
        loge(e, s);
      }
    });
  }

  Future _init() async {
    final setting = context.settings;
    final app = context.app;
    final chat = context.chat;
    final rwkv = context.rwkv;
    final modelManage = context.modelManage;

    await app.init().catchError((e, s) => loge(e, s));
    await rwkv.init().catchError((e, s) => loge(e, s));
    await chat.init().catchError((e, s) => loge(e, s));
    await modelManage.init().catchError((e, s) => loge(e, s));

    Future.delayed(const Duration(milliseconds: 500), () async {
      await setting.init();
      _syncAppearance(setting.state.appearance);
      modelManage.initManager(
        modelDownloadDir: setting.state.cache.modelDownloadDir,
        configProviderUrl: setting.state.model.modelListUrl,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MultiBlocListener(
        listeners: _buildStateSyncListeners(),
        child: widget.child,
      ),
    );
  }
}

List<BlocListener> _buildStateSyncListeners() {
  return [
    /// Sync native window brightness with appearance setting
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) =>
          p.appearance.theme.brightness != c.appearance.theme.brightness,
      listener: (context, state) {
        logd('appearance updated: ${state.appearance.theme.brightness}');
        _syncAppearance(state.appearance);
      },
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.appearance.userType != c.appearance.userType,
      listener: (context, state) {
        logd('user-type updated: ${state.appearance.userType}');
        context.app.onUserTypeChanged(state.appearance.userType);
      },
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.model.remoteServices != c.model.remoteServices,
      listener: (context, state) async {
        logd(
          'model-service-settings updated: ${state.model.remoteServices.length} services',
        );
        final app = context.app;
        final rwkv = context.rwkv;
        final modelManage = context.modelManage;
        await app.updateModelServices(state.model.remoteServices);
        rwkv.syncRemoteServiceInstances();
        await modelManage.updateModelList(local: false);
      },
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.python != c.python,
      listener: (context, state) async {
        logd('python updated: ${state.python.selected}');
        context.app.onPythonSelected(
          id: state.python.selected,
          albatrossPath: state.python.albatrossPath,
        );
      },
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.model.modelListUrl != c.model.modelListUrl,
      listener: (context, state) async {
        logd('model-list-url updated: ${state.model.modelListUrl}');
        context.modelManage.updateModelConfigUrl(state.model.modelListUrl);
      },
    ),

    if (!kIsWeb)
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) => p.model.modelServer != c.model.modelServer,
        listener: (context, state) async {
          logd(
            'model-server setting updated: ${state.model.modelServer.toMap()}',
          );

          if (!kIsWeb && state.model.modelServer.enabled) {
            final localOnly = state.model.modelServer.onlyLocalModel;
            final models = localOnly
                ? context.rwkv.state.localInstances
                : context.rwkv.state.models.values;
            context.app.onModelInstanceListChanged(models);
          }

          context.app.onModelServerSettingChanged(state.model.modelServer);
        },
      ),
    BlocListener<RwkvCubit, RwkvState>(
      listenWhen: (p, c) => p.models != c.models,
      listener: (context, state) {
        logd('model-instance updated: ${state.models.length} instances');

        if (!kIsWeb) {
          final localOnly =
              context.settings.state.model.modelServer.onlyLocalModel;
          final models = localOnly ? state.localInstances : state.models.values;
          context.app.onModelInstanceListChanged(models);
        }

        final chat = context.chat.state.modelInstanceId;
        final textGen = context.textGen.state.modelInstanceId;
        if (chat.isNotEmpty && state.models[chat] == null) {
          context.chat.onModelReleased();
        }
        if (textGen.isNotEmpty && state.models[textGen] == null) {
          context.textGen.onModelReleased();
        }
      },
    ),
  ];
}

void _syncAppearance(AppearanceSettingsModel appearance) {
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
