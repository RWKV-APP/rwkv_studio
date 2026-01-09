import 'dart:convert';
import 'dart:io';

import 'package:rwkv_studio/src/utils/logger.dart';

class PythonInterpreter {
  static Process? _process;

  static bool _isRunning = false;

  static bool get running => _isRunning;

  static Future<List<String>> getPythonPath() async {
    final res = await Process.run('where', ['python']);
    if (res.exitCode != 0) {
      return [];
    }
    final output = res.stdout.toString();
    return output
        .split('\n')
        .map((line) => line.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Future launch() async {
    if (_isRunning) {
      return;
    }
    final python = 'python';
    // final path = Platform.environment['PATH']?.split(';');
    // logd(path?.join('\n'));

    _process = await Process.start(python, ['-m', 'http.server', '8000']);
    logd('python: started');
    _process?.stdout.listen((data) {
      final str = utf8.decode(data);
      logd('python: $str');
    });
    _process?.stderr.listen((data) {
      loge('python: $data');
    });
    _isRunning = true;
    final code = await _process?.exitCode;
    _isRunning = false;
    logd('python: exit code: $code');
  }

  static Future shutdown() async {
    _process?.kill();
  }
}
