import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class AppAssets {
  static String rwkvVocab20230424 = '';
  static late List<String> rwkvVocab20230424Data;

  AppAssets._();

  static Future init() async {
    final name = 'b_rwkv_vocab_v20230424.txt';

    rwkvVocab20230424 = 'assets/rwkv/$name';

    if (kIsWeb) {
      final asset = await rootBundle.load(rwkvVocab20230424);
      final bytes = asset.buffer.asUint8List();
      rwkvVocab20230424Data = utf8
          .decode(bytes)
          .split('\n')
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList(growable: false);
      return;
    }
    final vocab = await _assetsPath(rwkvVocab20230424, name);
    rwkvVocab20230424 = vocab.path;
  }

  static Future<File> _assetsPath(String assets, String file) async {
    final dir = appExecutableDir.path;
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
