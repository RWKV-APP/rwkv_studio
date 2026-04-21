import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/network/http.dart';
import 'package:rwkv_studio/src/python/process.dart';
import 'package:rwkv_studio/src/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

class RwkvLightningLauncher {
  static int _startPort = 19527;

  final String executable;
  final String modelPath;
  final String vocabPath;
  final int port;

  RwkvLightningLauncher({
    required this.executable,
    required this.modelPath,
    required this.vocabPath,
  }) : port = _startPort++;

  Future<AlbatrossClient> startup() async {
    logd('Starting RWKV Lightning...');
    AppProcess process = await AppProcess.start(executable, [
      '--model-path',
      modelPath,
      '--vocab-path',
      vocabPath,
      '--port',
      port.toString(),
    ]);

    final wrap = _AlbatrossWrap('http://127.0.0.1:$port', process: process);
    await wrap._waitStart(port);

    logd('RWKV Lightning started.');
    return wrap;
  }
}

class _AlbatrossWrap extends AlbatrossClient {
  final AppProcess process;
  final List<String> _outputs = [];

  _AlbatrossWrap(super.baseUrl, {required this.process}) {
    process.outputs.listen(
      (e) {
        logd('[rwkv_lightning] $e');
        _outputs.add(e);
      },
      onError: (e, stack) {
        loge('[rwkv_lightning] $e', stack);
        _outputs.add(e.toString());
        _outputs.add(stack.toString());
      },
    );
  }

  Future _waitStart(String port) async {
    try {
      await Future.any([
        process.outputs.firstWhere(
          (e) => e.contains('Model loaded successfully'),
        ),
      ]);
    } on StateError {
      /// No output
      throw AppException.externalProcess(
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
