import 'dart:async';

import 'package:dio/dio.dart';

bool isTimeoutException(Object obj) {
  return obj is TimeoutException;
}

bool isCanceledException(Object obj) {
  switch (obj) {
    case DioException e:
      return e.type == DioExceptionType.cancel;
  }
  return false;
}
