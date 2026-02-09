import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:rwkv_studio/src/utils/logger.dart';

class CondaEnv {
  final String name;
  final String path;

  CondaEnv({required this.name, required this.path});
}

class Python {
  final CondaEnv? condaEnv;

  final String path;
  final String workingDir;
  final Map<String, dynamic> env;
  final Duration timeout;

  String get id => condaEnv?.path ?? path;

  String _version = '';

  bool get isValid => _version.isNotEmpty;

  String get version => _version;

  Python({
    required this.path,
    required this.workingDir,
    required this.env,
    required this.timeout,
    this.condaEnv,
  });

  factory Python.fromPath(
    String path, {
    String? workingDir,
    Map<String, dynamic> env = const {},
    Duration timeout = const Duration(seconds: 10),
  }) {
    return Python(
      path: path,
      workingDir: workingDir ?? File(Platform.script.path).parent.path,
      env: env,
      timeout: timeout,
    );
  }

  factory Python.fromCondaEnv(
    CondaEnv env, {
    String? workingDir,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return Python(
      path: '',
      condaEnv: env,
      workingDir: workingDir ?? File(Platform.script.path).parent.path,
      timeout: timeout,
      env: {},
    );
  }

  static Future<List<CondaEnv>> detectCondaEnv() async {
    /// await Process.run('bash', ['-lc', 'conda env list --json']);
    final res = await Process.run('conda', ['env', 'list', '--json']);
    if (res.exitCode != 0) {
      return [];
    }
    final json = jsonDecode(res.stdout.toString());
    final details = json['envs_details'] as Map;
    return [
      for (final e in details.entries)
        CondaEnv(name: e.value['name'], path: e.key),
    ].toList();
  }

  static Future<List<String>> findPythons() async {
    final res = await Process.run('where', ['python']);
    if (res.exitCode != 0) {
      return [];
    }
    final output = res.stdout.toString();
    return output.trim().split('\n').map((e) => e.trim()).toList();
  }

  Future<bool> validate() async {
    try {
      final output = await run(['--version']);
      _version = output.trim().split(' ')[1];
    } catch (e) {
      logw(e);
    }
    return true;
  }

  Future<String> run(List<String> args) async {
    ProcessResult res;
    final args_ = _formatArgs(args);
    logd('running process: ${args_.join(' ')}');
    if (condaEnv != null) {
      res = await Process.run('cmd', args_);
    } else {
      res = await Process.run(path, args_);
    }
    if (res.exitCode != 0) {
      throw 'process exited with code: ${res.exitCode}\n${res.stderr.toString()}'
          .trim();
    }
    final output = res.stdout.toString();
    return output;
  }

  Stream<String> start(List<String> args, {String? workingDir}) async* {
    Process process;
    final args_ = _formatArgs(args);
    logd('starting process: ${args_.join(' ')}');
    if (condaEnv != null) {
      process = await Process.start('cmd', args_, workingDirectory: workingDir);
    } else {
      process = await Process.start(path, args_, workingDirectory: workingDir);
    }
    final output = StreamController<String>();

    process.exitCode.then((e) {
      if (e != 0) {
        output.addError('process exited with code: $e');
      } else {
        logd('process exited, pid=${process.pid}');
      }
      output.close();
    });
    process.stdout.listen((e) => output.add(utf8.decode(e).trim()));
    process.stderr.listen((e) => output.add(utf8.decode(e).trim()));

    yield* output.stream;
  }

  List<String> _formatArgs(List<String> args) {
    if (condaEnv != null) {
      return [
        '/c',
        'conda',
        'run',
        '-n',
        condaEnv!.name,
        '--no-capture-output',
        'python',
        ...args,
      ];
    } else {
      return [path, ...args];
    }
  }
}
