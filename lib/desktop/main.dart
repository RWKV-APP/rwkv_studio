import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rwkv_studio/src/app/app.dart';
import 'package:rwkv_studio/src/app/init_config.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final initialConfig = await InitConfig.load();

  await Window.initialize();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      center: true,
      // size: Size(1000, 800),
      title: 'RWKV Studio',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();

      if (Platform.isWindows) {
        windowManager.setBrightness(
          initialConfig.isDark ? Brightness.dark : Brightness.light,
        );
      }
      await Window.setEffect(
        effect: Platform.isMacOS ? WindowEffect.hudWindow : WindowEffect.mica,
        dark: initialConfig.isDark,
      );
    });
  }

  if (Platform.isMacOS || Platform.isIOS) {
    try {
      appDataDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      loge(e);
    }
  }
  runApp(const RWKVApp());
}
