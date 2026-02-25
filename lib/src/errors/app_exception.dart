import 'package:dio/dio.dart';

extension Ext<T> on Future<T> {
  Future<T> wrapError() async {
    try {
      return await this;
    } catch (e) {
      throw AppException.wrap(e);
    }
  }
}

class AppException implements Exception {
  final String message;
  final dynamic stackTrace;
  final String? code;
  final dynamic cause;

  const AppException(this.message, {this.stackTrace, this.code, this.cause});

  static AppException wrap(dynamic e) {
    if (e is AppException) {
      return e;
    }
    if (e is DioException) {
      if (e.type == DioExceptionType.badResponse) {
        return AppException(
          'HTTP ${e.response?.statusCode} ${e.requestOptions.uri.toString()}'
              .trim(),
        );
      }
      return AppException("${e.type.name}, ${e.requestOptions.uri.toString()}");
    }
    return AppException(e.toString(), cause: e);
  }

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
