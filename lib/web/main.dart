import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_studio/src/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RWKVApp());

  await BrowserContextMenu.disableContextMenu();
}
