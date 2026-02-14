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

  AlbatrossLauncher({
    required this.python,
    required this.scriptPath,
    required this.modelPath,
  }) : port = _startPort++;

  Future<AlbatrossClient> startup() async {

    final workingDir = File(scriptPath).parent.path;
    final process = await python.start([
      scriptPath,
      '--model-path',
      modelPath,
      '--port',
      port.toString(),
    ], workingDir: workingDir);
    final wrap = _AlbatrossWrap('http://127.0.0.1:$port', process: process);
    await wrap._waitStart();
    return wrap;
  }
}

class _AlbatrossWrap extends AlbatrossClient {
  final PythonProcess process;
  final List<String> _outputs = [];

  _AlbatrossWrap(super.baseUrl, {required this.process}) {
    process.outputs.listen(
      (e) {
        _outputs.add(e);
      },
      onError: (e, stack) {
        loge('albatross error: $e', stack);
        _outputs.add(e.toString());
        _outputs.add(stack.toString());
      },
    );
  }

  Future _waitStart() async {
    try {
      await process.outputs.firstWhere(
        (e) => e.contains('Starting server at http://0.0.0.0:'),
      );
    } on StateError {
      /// No output
      throw Exception(
        'albatross startup failed, exit code: ${process.exitCode}',
      );
    }
  }

  @override
  Future<String> dumpLog() {
    return Future.value(_outputs.join('\n'));
  }

  @override
  Future<dynamic> release() async {
    process.kill();
  }
}
