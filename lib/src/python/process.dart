import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rwkv_studio/src/utils/logger.dart';

class AppProcess {
  final _output = StreamController<String>.broadcast();
  final Process _process;
  int _exitCode = -1;

  Stream<String> get outputs => _output.stream;

  int get pid => _process.pid;

  int get exitCode => _exitCode;

  AppProcess._(this._process) {
    _process.exitCode.then((e) {
      _exitCode = e;
      if (e != 0 && !_output.isClosed) {
        _output.addError('process exited with code: $e');
      } else {
        logd('process exited, pid=${_process.pid}, code=$e');
      }
      if (!_output.isClosed) {
        _output.close();
      }
    });
    _process.stdout.listen((e) {
      if (!_output.isClosed) {
        _output.add(utf8.decode(e).trim());
      }
    });
    _process.stderr.listen((e) {
      if (!_output.isClosed) {
        _output.add(utf8.decode(e).trim());
      }
    });
  }

  static Future<AppProcess> start(
    String executable,
    List<String> args, {
    String? workingDir,
  }) async {
    final command = _resolveCommand(executable, args);
    await _ensureExecutablePermission(command.executable);

    Process process = await Process.start(
      command.executable,
      command.args,
      workingDirectory: workingDir,
      mode: ProcessStartMode.normal,
    );
    logd(
      'process ${process.pid} started '
      '${[command.executable, ...command.args].join(' ')}',
    );
    return AppProcess._(process);
  }

  static ({String executable, List<String> args}) _resolveCommand(
    String executable,
    List<String> args,
  ) {
    if (Platform.isWindows || executable != 'cmd' || args.isEmpty) {
      return (executable: executable, args: args);
    }

    final resolvedArgs = args.first == '/c' ? args.sublist(1) : args;
    if (resolvedArgs.isEmpty) {
      return (executable: executable, args: args);
    }
    return (
      executable: resolvedArgs.first,
      args: resolvedArgs.sublist(1),
    );
  }

  static Future<void> _ensureExecutablePermission(String executable) async {
    if (Platform.isWindows) {
      return;
    }

    final file = File(executable);
    if (!await file.exists()) {
      return;
    }

    final stat = await file.stat();
    const executableBits = 0x49;
    if (stat.mode & executableBits != 0) {
      return;
    }

    final result = await Process.run('chmod', ['u+x', executable]);
    if (result.exitCode != 0) {
      throw ProcessException(
        'chmod',
        ['u+x', executable],
        result.stderr.toString().trim(),
        result.exitCode,
      );
    }
    logd('executable permission granted: $executable');
  }

  Future kill() async {
    _process.kill();
    if (!_output.isClosed) {
      await _output.close();
    }
  }
}
