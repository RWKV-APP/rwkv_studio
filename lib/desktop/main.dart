import 'dart:io';

import 'package:detect_proxy_setting/detect_proxy_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_downloader/rwkv_downloader.dart';
import 'package:rwkv_studio/src/app/app.dart';
import 'package:rwkv_studio/src/app/init_config.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  if (!Platform.isWindows) {
    try {
      appDataDir = await getApplicationSupportDirectory().catchError(
        (e) => getApplicationCacheDirectory(),
      );
    } catch (e) {
      loge(e);
    }
  }

  WidgetsFlutterBinding.ensureInitialized();

  final initialConfig = await InitConfig.load();

  WindowOptions windowOptions = const WindowOptions(
    center: true,
    // size: Size(1000, 800),
    title: 'RWKV Studio',
    windowButtonVisibility: true,
  );
  _detectSystemProxy();

  await WindowManager.instance.ensureInitialized();

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    windowManager.setBrightness(
      initialConfig.isDark ? Brightness.dark : Brightness.light,
    );

    await windowManager.show();
    await windowManager.focus();
  });

  if (Platform.isWindows) {
    await Window.initialize();
    await Window.setEffect(
      effect: Platform.isMacOS ? WindowEffect.hudWindow : WindowEffect.mica,
      dark: initialConfig.isDark,
    );
  }
  runApp(const RWKVApp());
}

void _detectSystemProxy() async {
  if (Platform.isLinux) {
    logw('detect system proxy not supported on Linux yet');
    return;
  }
  final ProxySetting? setting = await proxySetting();

  if (setting?.mode == .proxy) {
    final String proxy = setting!.proxy;
    DownloadManager.init(proxy: "PROXY $proxy; DIRECT");
    logd('Proxy enabled: $proxy');
  }
}
