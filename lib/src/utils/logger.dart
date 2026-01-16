import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

final _logger = Logger('rwkv-studio');

bool _loggerInitialized = false;

class Log {
  final String tag;
  final String level;
  final String message;
  final DateTime datetime;

  Log({
    required this.tag,
    required this.level,
    required this.message,
    required this.datetime,
  });

  @override
  String toString() {
    return '$tag/$level: $message';
  }
}

class AppLog with ChangeNotifier {
  final List<Log> history = [];

  static final instance = AppLog();

  void _log(Log log) {
    print(log);
    history.add(log);
    if (history.length > 100) {
      history.removeAt(0);
    }
    notifyListeners();
  }
}

void _listenToLogs() {
  if (_loggerInitialized) {
    return;
  }

  _loggerInitialized = true;
  Logger.root.clearListeners();
  Logger.root.onRecord.listen((record) {
    final log = Log(
      tag: record.loggerName,
      level: record.level.name,
      message: record.message,
      datetime: record.time,
    );
    AppLog.instance._log(log);
  });
}

void logv(dynamic msg) {
  _listenToLogs();
  _logger.fine(msg);
}

void logi(dynamic msg) {
  _listenToLogs();
  _logger.config(msg);
}

void logd(dynamic msg) {
  _listenToLogs();
  _logger.info(msg);
}

void logw(dynamic msg) {
  _listenToLogs();
  _logger.warning(msg);
}

void loge(dynamic msg) {
  _listenToLogs();
  _logger.severe(msg);
}

void logwtf(dynamic msg) {
  _listenToLogs();
  _logger.shout(msg);
}
