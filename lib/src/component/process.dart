import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

extension Ext on ProcessResult {
  String get stdoutStr {
    if (this.stdout is String) {
      return (this.stdout as String).trim();
    } else if (this.stdout == null) {
      return '';
    } else if (this.stdout is List<int>) {
      return utf8.decode(this.stdout).trim();
    } else {
      return this.stdout.toString().trim();
    }
  }

  String get stderrStr {
    if (this.stderr is String) {
      return this.stderr as String;
    } else if (this.stderr == null) {
      return '';
    } else if (this.stderr is List<int>) {
      return utf8.decode(this.stderr);
    } else {
      return this.stderr.toString();
    }
  }
}

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
        _output.addError(
          AppException.externalProcess('process $pid exited with code: $e'),
        );
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

  static Future<ProcessResult> run(
    String executable,
    List<String> args, {
    String? workingDir,
  }) async {
    final r = await Process.run(executable, args, workingDirectory: workingDir);
    if (r.exitCode != 0) {
      throw ProcessException(executable, args, r.stderr, r.exitCode);
    }
    return r;
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
    return (executable: resolvedArgs.first, args: resolvedArgs.sublist(1));
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
