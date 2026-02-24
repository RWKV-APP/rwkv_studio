import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final dynamic stackTrace;
  final String? code;
  final dynamic cause;

  const AppException(this.message, {this.stackTrace, this.code, this.cause});

  bool shouldToast() {
    if (cause is DioException) {
      if ((cause as DioException).type == DioExceptionType.cancel) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() {
    if (cause != null) {
      return '$message: $cause';
    }
    return message;
  }
}
