import 'dart:async';

import 'package:dio/dio.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';

bool isTimeoutException(Object obj) {
  return obj is TimeoutException ||
      (obj is AppException && obj.kind == AppExceptionKind.timeout);
}

bool isCanceledException(Object obj) {
  if (obj is AppException) {
    return obj.kind == AppExceptionKind.cancelled;
  }
  switch (obj) {
    case DioException e:
      return e.type == DioExceptionType.cancel;
  }
  return false;
}
