import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

extension Ext<T> on Future<T> {
  Future<T> wrapError() async {
    try {
      return await this;
    } catch (e, s) {
      Error.throwWithStackTrace(AppException.wrap(e, s), s);
    }
  }
}

enum AppExceptionKind {
  validation,
  configuration,
  notFound,
  network,
  timeout,
  cancelled,
  storage,
  unsupported,
  externalProcess,
  internal,
  unimplemented,
  unknown,
}

class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;
  final AppExceptionKind kind;
  final String? code;
  final Object? cause;

  const AppException(
    this.message, {
    this.stackTrace,
    this.kind = AppExceptionKind.unknown,
    this.code,
    this.cause,
  });

  const AppException.validation(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.validation,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.configuration(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.configuration,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.notFound(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.notFound,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.network(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.network,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.timeout(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.timeout,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.cancelled(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.cancelled,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.storage(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.storage,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.unsupported(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.unsupported,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.externalProcess(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.externalProcess,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.internal(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.internal,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.unimplemented(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.unimplemented,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  const AppException.unknown(
    String message, {
    StackTrace? stackTrace,
    String? code,
    Object? cause,
  }) : this(
         message,
         kind: AppExceptionKind.unknown,
         stackTrace: stackTrace,
         code: code,
         cause: cause,
       );

  AppException copyWith({
    String? message,
    StackTrace? stackTrace,
    AppExceptionKind? kind,
    String? code,
    Object? cause,
  }) {
    return AppException(
      message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      kind: kind ?? this.kind,
      code: code ?? this.code,
      cause: cause ?? this.cause,
    );
  }

  bool get isCancelled => kind == AppExceptionKind.cancelled;

  String get displayMessage => message;

  static AppException wrap(Object e, [StackTrace? stackTrace]) {
    if (e is AppException) {
      if (e.stackTrace != null || stackTrace == null) {
        return e;
      }
      return e.copyWith(stackTrace: stackTrace);
    }
    if (e is DioException) {
      return _wrapDio(e, stackTrace);
    }
    if (e is TimeoutException) {
      return AppException.timeout(
        e.message ?? 'Operation timed out',
        cause: e,
        stackTrace: stackTrace,
      );
    }
    if (e is FileSystemException) {
      return AppException.storage(
        e.message,
        code: e.osError?.errorCode.toString(),
        cause: e,
        stackTrace: stackTrace,
      );
    }
    if (e is ProcessException) {
      return AppException.externalProcess(
        e.message,
        code: e.errorCode.toString(),
        cause: e,
        stackTrace: stackTrace,
      );
    }
    if (e is FormatException) {
      return AppException.validation(
        e.message,
        cause: e,
        stackTrace: stackTrace,
      );
    }
    if (e is UnsupportedError || e is UnimplementedError) {
      return AppException.unimplemented(
        e.toString(),
        cause: e,
        stackTrace: stackTrace,
      );
    }
    if (e is StateError || e is ArgumentError || e is AssertionError) {
      return AppException.internal(
        e.toString(),
        cause: e,
        stackTrace: stackTrace,
      );
    }
    return AppException.unknown(e.toString(), cause: e, stackTrace: stackTrace);
  }

  static AppException _wrapDio(DioException e, StackTrace? stackTrace) {
    final uri = e.requestOptions.uri.toString();
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return AppException.timeout(
          'Connection timed out',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.sendTimeout:
        return AppException.timeout(
          'Send timed out',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.receiveTimeout:
        return AppException.timeout(
          'Receive timed out',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badCertificate:
        return AppException.network(
          'Bad certificate: $uri',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.badResponse:
        final resp = e.response;
        final status = resp?.statusCode;
        final statusMessage = resp?.statusMessage ?? '';
        final msg = 'HTTP ${status ?? ''} ${statusMessage.trim()} $uri'.trim();
        return AppException.network(
          msg,
          code: status?.toString(),
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.connectionError:
        return AppException.network(
          'Connection error: $uri',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.cancel:
        return AppException.cancelled(
          'Request cancelled',
          cause: e,
          stackTrace: stackTrace,
        );
      case DioExceptionType.unknown:
        return AppException.network(
          'Network error: $uri',
          cause: e,
          stackTrace: stackTrace,
        );
    }
  }

  @override
  String toString() {
    if (cause != null) {
      return '$message: $cause';
    }
    return message;
  }
}
