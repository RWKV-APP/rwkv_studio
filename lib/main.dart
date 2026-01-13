import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:rwkv_studio/src/app/app.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await Window.initialize();
    WindowOptions windowOptions = WindowOptions(
      center: true,
      size: Size(1000, 800),
      title: 'RWKV Studio',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await Window.setEffect(effect: WindowEffect.mica, dark: false);
    });
  }
  runApp(const RWKVApp());
}
