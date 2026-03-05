import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _logger = Logger('RWKVStudio');

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
    return message;
    return '$level/$tag: $message';
  }
}

class AppLog with ChangeNotifier {
  final List<Log> history = [];

  static final instance = AppLog();

  void _log(Log log) {
    history.add(log);
    if (history.length > 100) {
      history.removeAt(0);
    }
    notifyListeners();
  }

  static void captureZone(Function() entry) {
    runZonedGuarded(
      entry,
      (error, stackTrace) {
        stderr.writeln(error.toString());
        instance._log(
          Log(
            tag: '',
            level: '',
            message: error.toString(),
            datetime: DateTime.now(),
          ),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          stdout.writeln(line);
          AppLog.instance._log(
            Log(tag: '', level: '', message: line, datetime: DateTime.now()),
          );
        },
      ),
    );
  }
}

void _listenToLogs() {
  if (_loggerInitialized) {
    return;
  }

  _loggerInitialized = true;
  Logger.root.clearListeners();
  Logger.root.level = Level.ALL;

  Logger.root.onRecord.listen((record) {
    final log = Log(
      tag: record.loggerName,
      level: record.level.name.replaceAll('CONFIG', 'DEBUG'),
      message: record.message,
      datetime: record.time,
    );
    print(log.toString());
  });
}

void logv(dynamic msg) {
  _listenToLogs();
  _logger.fine(msg);
}

void logi(dynamic msg) {
  _listenToLogs();
  _logger.info(msg);
}

void logd(dynamic msg) {
  _listenToLogs();
  _logger.config("${_fileName()}$msg");
}

void logw(dynamic msg) {
  _listenToLogs();
  _logger.warning(msg);
  if (!kIsWeb) {
    _logger.warning(StackTrace.current.toString().split('\n')[1].trim());
  }
}

void loge(dynamic msg, [Object? error, StackTrace? stackTrace]) {
  _listenToLogs();
  _logger.severe(msg, error, stackTrace);
  if (!kIsWeb) {
    _logger.severe(StackTrace.current.toString().split('\n')[1].trim());
  }
}

void logwtf(dynamic msg) {
  _listenToLogs();
  _logger.shout(msg);
}

String _fileName() {
  return '';
  final line = StackTrace.current.toString().split('\n')[2].trim();
  return "${line.substring(line.indexOf('(') + 1, line.indexOf(')'))}\n";
}
