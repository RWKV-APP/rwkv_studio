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

    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return const AppException('Connection timed out');
        case DioExceptionType.sendTimeout:
          return const AppException('Send timed out');
        case DioExceptionType.receiveTimeout:
          return const AppException('Receive timed out');
        case DioExceptionType.badCertificate:
          return const AppException('Bad certificate');
        case DioExceptionType.badResponse:
          final resp = e.response;
          final status = resp?.statusCode;
          if (resp != null && status != null && status >= 400) {
            // final body = resp.data;
            String msg =
                "HTTP ${resp.statusCode} ${resp.statusMessage}  ${e.requestOptions.uri}";
            return AppException(msg);
          }
        case DioExceptionType.connectionError:
          return const AppException('Connection error');
        case DioExceptionType.cancel:
          return const AppException('Request cancelled');
        case DioExceptionType.unknown:
          return const AppException('Unknown error');
      }
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
