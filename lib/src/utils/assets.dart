import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rwkv_studio/src/utils/path.dart';

class AppAssets {
  static String rwkvVocab20230424 = '';

  AppAssets._();

  static Future init() async {
    final name = 'b_rwkv_vocab_v20230424.txt';

    if (kIsWeb) {
      return;
    }

    final vocab = await _assetsPath('assets/rwkv/$name', name);
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
