import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:rwkv_studio/src/utils/date_utils.dart';

final _logger = Logger('STUDIO');

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
        if (kIsWeb) {
          //
        } else {
          stderr.writeln(error.toString());
          stderr.writeln(stackTrace.toString());
        }
        instance._log(
          Log(
            tag: '',
            level: '',
            message: "${error.toString()}\n${stackTrace.toString()}",
            datetime: DateTime.now(),
          ),
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          if (kIsWeb) {
          } else {
            stdout.writeln(line);
          }
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
    print(
      "${record.time.displayTime}: ${record.loggerName}/${record.level.name}: ${_formatRecordMessage(record)}",
    );
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
  _logger.config("$msg");
}

void logw(dynamic msg) {
  _listenToLogs();
  _logger.warning(msg);
  if (!kIsWeb) {
    // _logger.warning(StackTrace.current.toString().split('\n')[1].trim());
  }
}

void loge(dynamic msg, [Object? error, StackTrace? stackTrace]) {
  _listenToLogs();
  final resolved = _resolveErrorLog(msg, error, stackTrace);
  _logger.severe(resolved.message, resolved.error, resolved.stackTrace);
  if (stackTrace != null) {
    _logger.severe(stackTrace.toString());
  }
  if (!kIsWeb) {
    _logger.severe(StackTrace.current.toString().split('\n')[1].trim());
  }
}

void logwtf(dynamic msg) {
  _listenToLogs();
  _logger.shout(msg);
}

String _formatRecordMessage(LogRecord record) {
  final parts = <String>[record.message];
  if (record.error != null &&
      record.error.toString() != record.message.toString()) {
    parts.add(record.error.toString());
  }
  if (record.stackTrace != null) {
    parts.add(record.stackTrace.toString());
  }
  return parts.join('\n');
}

({String message, Object? error, StackTrace? stackTrace}) _resolveErrorLog(
  dynamic msg,
  Object? error,
  StackTrace? stackTrace,
) {
  if (msg is StackTrace && error == null && stackTrace == null) {
    return (message: msg.toString(), error: null, stackTrace: msg);
  }

  if (error is StackTrace && stackTrace == null) {
    return (message: msg.toString(), error: null, stackTrace: error);
  }

  return (message: msg.toString(), error: error, stackTrace: stackTrace);
}
