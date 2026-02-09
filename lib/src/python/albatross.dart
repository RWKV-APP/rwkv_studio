import 'dart:io';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

import 'interpreter.dart';

class AlbatrossLauncher {
  static int _startPort = 9527;

  final Python python;
  final String scriptPath;
  final String modelPath;
  final int port;

  final List<String> _outputs = [];

  List<String> get outputs => _outputs;

  AlbatrossLauncher({
    required this.python,
    required this.scriptPath,
    required this.modelPath,
  }) : port = _startPort++;

  Future<AlbatrossClient> startup() async {
    final workingDir = File(scriptPath).parent.path;
    final out = python.start([
      scriptPath,
      '--model-path',
      modelPath,
      '--port',
      port.toString(),
    ], workingDir: workingDir).asBroadcastStream();
    out.listen(
      (e) {
        logd('python: $e');
        _outputs.add(e);
      },
      onError: (e) {
        loge('albatross error: $e');
      },
    );
    await out.firstWhere(
      (e) => e.contains('Starting server at http://0.0.0.0:$port'),
    );
    logd('albatross server started');
    // todo binding lifecycle with python process
    return AlbatrossClient('http://127.0.0.1:$port');
  }
}
