import 'dart:async';
import 'dart:convert';

import 'package:rwkv_studio/src/component/process.dart';
import 'package:rwkv_studio/src/component/toolkit/hardware_model.dart';
import 'package:rwkv_studio/src/component/toolkit/usage_model.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

class Toolkit {
  static String _bin = '';
  static AppProcess? _process;
  static final StreamController<HardwareUsageModel> _usageController =
      StreamController<HardwareUsageModel>.broadcast();
  static int _interval = 3000;
  static int _pid = 0;

  static Future init(String bin) async {
    kill();
    _bin = bin;
    final ver = await _exec(['version']);
    logd('toolkit $ver initialized');
    _watchHardwareUsage();
  }

  static Future kill() async {
    _process?.kill();
    _process = null;
  }

  static Future<HardwareModel> getHardwareInfo() async {
    final out = await _exec(['info']);
    final json = jsonDecode(out);
    return HardwareModel.fromJson(json);
  }

  static Stream<HardwareUsageModel> watchHardwareUsage({
    int pid = 0,
    int interval = 3,
  }) {
    _pid = pid;
    _interval = interval;
    return _usageController.stream;
  }

  static void _watchHardwareUsage() async {
    logd('start watch hardware usage');
    final proc = await AppProcess.start(_bin, [
      'usage',
      '-watch',
      '-interval=$_interval',
      '-pid=$_pid',
    ]);

    _process = proc;
    await for (var line in proc.outputs) {
      final json = jsonDecode(line);
      final r = HardwareUsageModel.fromJson(json);
      _usageController.add(r);
    }
    _process = null;
    logd('hardware usage watch stopped');
  }

  static Future<HardwareUsageModel> getHardwareUsage() async {
    final c = await _exec(['usage']);
    final json = jsonDecode(c);
    return HardwareUsageModel.fromJson(json);
  }

  static Future<String> _exec(List<String> args) async {
    if (_bin.isEmpty) {
      throw const AppException.illegalState('toolkit not initialized');
    }
    final proc = await AppProcess.run(_bin, [...args]);
    final out = proc.stdoutStr;
    return out;
  }
}
