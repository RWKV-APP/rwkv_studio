import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/bloc/app/app_cubit.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_provider.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
import 'package:rwkv_studio/src/cache/hive_manager.dart';
import 'package:rwkv_studio/src/contract/user_type.dart';
import 'package:rwkv_studio/src/utils/assets.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/toast_util.dart';
import 'package:window_manager/window_manager.dart';

class WithGlobalStateSync extends StatefulWidget {
  final Widget child;

  const WithGlobalStateSync({super.key, required this.child});

  @override
  State<WithGlobalStateSync> createState() => _WithGlobalStateSyncState();
}

class _WithGlobalStateSyncState extends State<WithGlobalStateSync> {
  static bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _init();
      } catch (e) {
        logw(e);
      }
      _initialized = true;
      setState(() {});
    });
  }

  Future _init() async {
    if (_initialized) {
      return;
    }

    try {
      await AppAssets.init().withToast(
        context,
        error: 'Assets initialization failed',
      );
      if (!mounted) return;
      await HiveManager.init().withToast(
        context,
        error: 'Database initialization failed',
      );
      await HiveManager.openPreferencesBox();
    } catch (e) {
      logw(e);
    }
    if (!mounted) return;

    final setting = context.settings;
    final app = context.app;
    final chat = context.chat;
    final rwkv = context.rwkv;
    final modelManage = context.modelManage;

    await app.init();
    await rwkv.init();
    await chat.init();
    await modelManage.init();

    Future.delayed(const Duration(milliseconds: 1000), () {
      setting.init();
    });

    //
    // _syncAppearance(setting.state.appearance);
    //
    // if (mounted) {
    //   context.rwkv.setRemoteServiceList(app.state.modelServices);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _buildStateSyncListeners(widget.child),
    );
  }
}

Widget _buildStateSyncListeners(Widget child) {
  return Stack(
    fit: StackFit.expand,
    children: [
      child,

      /// Sync native window brightness with appearance setting
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) =>
            p.appearance.theme.brightness != c.appearance.theme.brightness,
        listener: (context, state) {
          logd('appearance changed: ${state.appearance.theme.brightness}');
          _syncAppearance(state.appearance);
        },
        child: const SizedBox(),
      ),
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) => p.appearance.userType != c.appearance.userType,
        listener: (context, state) {
          logd('user-type changed: ${state.appearance.userType}');
          context.app.onUserTypeChanged(state.appearance.userType);
        },
        child: const SizedBox(),
      ),
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) => p.model.remoteServices != c.model.remoteServices,
        listener: (context, state) async {
          logd(
            'model-service changed: ${state.model.remoteServices.length} services',
          );
          context.app.updateModelServices(state.model.remoteServices);
        },
        child: const SizedBox(),
      ),
      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) => p.python != c.python,
        listener: (context, state) async {
          logd('python changed: ${state.python.selected}');
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
          logd('model-list-url changed: ${state.model.modelListUrl}');
          context.modelManage.updateModelConfigUrl(state.model.modelListUrl);
        },
        child: const SizedBox(),
      ),
      BlocListener<ModelManageCubit, ModelManageState>(
        listenWhen: (p, c) => p.shouldModelListUpdate(p),
        listener: (context, state) {
          logd(
            'model-list changed: ${state.allModels.length} models, '
            '${state.availableModels.length} available',
          );
        },
        child: const SizedBox(),
      ),

      BlocListener<AppCubit, AppState>(
        listenWhen: (p, c) => p.modelServices != c.modelServices,
        listener: (context, state) async {
          logd('model-service changed: ${state.modelServices.length} services');
          final services = state.modelServices;
          final providers = services
              .map(ModelListProvider.fromService)
              .toList();
          context.modelManage.setModelProviders(providers);
          await context.rwkv.setRemoteServiceList(services);
        },
        child: const SizedBox(),
      ),
      BlocListener<RwkvCubit, RwkvState>(
        listenWhen: (p, c) => p.models.length != c.models.length,
        listener: (context, state) {
          logd('model-instance changed: ${state.models.length} instances');
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
    ],
  );
}

void _syncAppearance(AppearanceSettingState appearance) {
  final isLight = appearance.theme == AppearanceSettingState.lightTheme;
  if (isLight) {
    WindowManager.instance.setBrightness(Brightness.light);
  } else {
    WindowManager.instance.setBrightness(Brightness.dark);
  }
  Window.setEffect(effect: WindowEffect.mica, dark: !isLight);
}
