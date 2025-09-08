import 'dart:convert';

import 'package:dio/dio.dart';

class HTTP {
  static final demo = HTTP('http://192.168.0.79:5000');

  final Dio _dio;

  HTTP(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  Future post(String path, Map<String, dynamic> body) {
    return _dio.post(
      path,
      data: body,
      options: Options(contentType: "application/json"),
    );
  }
}
