import 'dart:async';

import 'package:rwkv_dart/rwkv_dart.dart';
import 'package:rwkv_studio/src/component/process.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class RwkvLightningCpp extends AlbatrossClient {
  static int _startPort = 19527;

  final String executable;
  final int port;
  final List<String> _outputs = [];

  late AppProcess process;

  RwkvLightningCpp._(super.baseUrl, this.port, {required this.executable});

  static Future<RWKV> create({required String executable}) async {
    final port = _startPort++;
    return RwkvLightningCpp._(
      'http://127.0.0.1:$port',
      port,
      executable: executable,
    );
  }

  @override
  Future<dynamic> init([InitParam? param]) async {
    //
    return super.init(param);
  }

  @override
  Future<int> loadModel(LoadModelParam param) async {
    logd('RWKV Lightning load model ${param.modelPath}');
    process = await AppProcess.start(executable, [
      '--model-path',
      param.modelPath,
      '--vocab-path',
      param.tokenizerPath,
      '--port',
      port.toString(),
    ]);

    Completer completer = Completer();

    process.outputs.listen(
      (e) {
        logd('[rwkv_lightning] $e');
        if (!completer.isCompleted && e.contains('Model loaded successfully')) {
          completer.complete();
        }
        _outputs.add(e);
      },
      onError: (e, stack) {
        loge('[rwkv_lightning] $e', stack);
        _outputs.add(e.toString());
        _outputs.add(stack.toString());
        completer.completeError(e, stack);
      },
    );

    if (process.existed) {
      completer.completeError(
        'Process existed: ${process.pid}, code: ${process.exitCode}',
      );
    }

    await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 10)),
    ]);

    logd('RWKV Lightning load model successfully.');
    return super.loadModel(param);
  }

  @override
  Future<String> dumpLog() {
    return Future.value(_outputs.join('\n'));
  }

  @override
  Future<dynamic> release() async {
    process.kill();
    return super.release();
  }
}
