import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';
import 'package:rwkv_studio/src/utils/rwkv_tokenizer.dart';

class AppAssets {
  static const String rwkvVocab20230424 = '';

  AppAssets._();

  static Future init() async {
    final name = 'b_rwkv_vocab_v20230424.txt';
    final asset = await rootBundle.load('assets/rwkv/$name');
    final bytes = asset.buffer.asUint8List();
    RwkvTokenizer.rwkvVocab20230424Data = utf8
        .decode(bytes)
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
    logd('b_rwkv_vocab_v20230424 loaded');
  }

  static Future<File> _assetsPath(String assets, String file) async {
    final dir = appDataDir.path;
    final f = File(pathJoin(dir, pathJoin('data', file)));
    if (await f.exists()) {
      return f;
    } else {
      await f.create(recursive: true);
    }
    final asset = await rootBundle.load(assets);
    await f.writeAsBytes(asset.buffer.asUint8List());
    logd('assets copied: ${f.path}');
    return f;
  }
}
