import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_studio/src/app/app.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

void main() async {
  loggerIsWeb = true;

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RWKVApp());

  await BrowserContextMenu.disableContextMenu();
}
