import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_provider.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/utils/collection_extensions.dart';
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
      child: Stack(
        fit: StackFit.expand,
        children: [widget.child, ..._buildStateSyncListeners()],
      ),
    );
  }
}

List<Widget> _buildStateSyncListeners() {
  return [
    /// Sync native window brightness with appearance setting
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) =>
          p.appearance.theme.brightness != c.appearance.theme.brightness,
      listener: (context, state) {
        logd('appearance updated: ${state.appearance.theme.brightness}');
        _syncAppearance(state.appearance);
      },
      child: const SizedBox(),
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.appearance.userType != c.appearance.userType,
      listener: (context, state) {
        logd('user-type updated: ${state.appearance.userType}');
        context.app.onUserTypeChanged(state.appearance.userType);
      },
      child: const SizedBox(),
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.model.remoteServices != c.model.remoteServices,
      listener: (context, state) async {
        logd(
          'model-service-settings updated: ${state.model.remoteServices.length} services',
        );
        context.app.updateModelServices(state.model.remoteServices);
      },
      child: const SizedBox(),
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
      child: const SizedBox(),
    ),
    BlocListener<SettingCubit, SettingState>(
      listenWhen: (p, c) => p.model.modelListUrl != c.model.modelListUrl,
      listener: (context, state) async {
        logd('model-list-url updated: ${state.model.modelListUrl}');
        context.modelManage.updateModelConfigUrl(state.model.modelListUrl);
      },
      child: const SizedBox(),
    ),

    if (!kIsWeb)
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) => p.model.modelServer != c.model.modelServer,
        listener: (context, state) async {
          logd(
            'model-server setting updated: ${state.model.modelServer.toMap()}',
          );
          context.app.onModelServerSettingChanged(state.model.modelServer);
        },
        child: const SizedBox(),
      ),

    BlocListener<AppCubit, AppState>(
      listenWhen: (p, c) => p.modelServices != c.modelServices,
      listener: (context, state) async {
        final services = state.modelServices;
        final providers = services.map(ModelListProvider.fromService).toList();

        final m = services.flatten((e) => e.models);
        logd(
          'model-service connected: ${services.length} services, ${m.length} models',
        );

        /// NOTE: MUST BE CALLED BEFORE `setModelProviders`
        /// avoid refreshing model list when model providers are not ready
        context.rwkv.setRemoteServiceList(services);

        context.modelManage.setModelProviders(providers);
      },
      child: const SizedBox(),
    ),
    BlocListener<RwkvCubit, RwkvState>(
      listenWhen: (p, c) => p.models.length != c.models.length,
      listener: (context, state) {
        logd('model-instance updated: ${state.models.length} instances');

        if (!kIsWeb)
          context.app.onLoadLocalModelListChanged(state.localInstances);

        final chat = context.chat.state.modelInstanceId;
        final textGen = context.textGen.state.modelInstanceId;
        if (chat.isNotEmpty && state.models[chat] == null) {
          context.chat.onModelReleased();
        }
        if (textGen.isNotEmpty && state.models[textGen] == null) {
          context.textGen.onModelReleased();
        }
      },
      child: const SizedBox(),
    ),
  ];
}

void _syncAppearance(AppearanceSettingState appearance) {
  if (kIsWeb) {
    return;
  }
  final isLight = appearance.theme == AppearanceSettingState.lightTheme;
  if (isLight) {
    WindowManager.instance.setBrightness(Brightness.light);
  } else {
    WindowManager.instance.setBrightness(Brightness.dark);
  }
  Window.setEffect(effect: WindowEffect.mica, dark: !isLight);
}
