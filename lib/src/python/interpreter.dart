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

  Future<int> validate() async {
    ProcessResult res;
    if (condaEnv != null) {
      res = await Process.run('cmd', [
        '/c',
        'conda',
        'run',
        '-n',
        condaEnv!.name,
        '--no-capture-output',
        'python',
        '--version',
      ]);
    } else {
      res = await Process.run(path, ['--version']);
    }
    if (res.exitCode != 0) {
      logw('python: validate failed: ${res.exitCode}\n$path');
      return res.exitCode;
    }

    final output = res.stdout.toString();
    _version = output.trim().split(' ')[1];
    logd('python: $_version\n$path');
    return 0;
  }
}
