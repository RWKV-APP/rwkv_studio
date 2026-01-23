import 'package:flutter/widgets.dart';
import 'package:flutter_acrylic/window.dart';
import 'package:flutter_acrylic/window_effect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rwkv_studio/src/bloc/chat/chat_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_manage_cubit.dart';
import 'package:rwkv_studio/src/bloc/model/model_provider.dart';
import 'package:rwkv_studio/src/bloc/rwkv/rwkv_cubit.dart';
import 'package:rwkv_studio/src/bloc/settings/setting_cubit.dart';
import 'package:rwkv_studio/src/bloc/text_gen/text_generation_cubit.dart';
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _syncSetting2AppState();
      } catch (e) {
        logw(e);
      }
      _initialized = true;
      setState(() {});
    });
  }

  Future _syncSetting2AppState() async {
    final setting = context.settings;
    if (setting.state.initialized) {
      return;
    }
    AppAssets.init().withToast(context);

    final modelManage = context.modelManage;

    await setting.init();
    await context.rwkv.init();

    modelManage.init(
      modelDir: setting.state.cache.modelDownloadDir,
      configUrl: setting.state.service.modelListUrl,
    );

    if (mounted) {
      _syncRemoteServiceList(context, setting.state.service.remoteServices);
    }
    _syncAppearance(setting.state.appearance);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return widget.child;
    }
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
          _syncAppearance(state.appearance);
        },
        child: Container(),
      ),

      BlocListener<SettingCubit, SettingState>(
        listenWhen: (p, c) =>
            p.service.remoteServices != c.service.remoteServices,
        listener: (context, state) async {
          _syncRemoteServiceList(context, state.service.remoteServices);
        },
        child: SizedBox(),
      ),
      BlocListener<ModelManageCubit, ModelManageState>(
        listenWhen: (p, c) => p.models != c.models,
        listener: (context, state) {
          logd(
            'model-list changed: ${state.models.length} models, '
            '${state.availableModels.length} available',
          );
        },
        child: SizedBox(),
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
        child: SizedBox(),
      ),
    ],
  );
}

Future _syncRemoteServiceList(
  BuildContext context,
  List<RemoteService> remoteServices,
) async {
  final services = remoteServices.where((e) => e.enabled);
  final rwkvCubit = context.rwkv;
  await rwkvCubit.setRemoteServiceList({
    for (final service in services) service.id: service.url,
  });
  final providers = rwkvCubit.state.services
      .map(ModelListProvider.fromService)
      .toList();
  if (context.mounted) context.modelManage.setModelProviders(providers);
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
