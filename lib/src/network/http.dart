import 'dart:convert';

import 'package:dio/dio.dart';

class HTTP {
  static final _instance = HTTP('http://192.168.0.79:5000');

  final Dio _dio;

  HTTP(String baseUrl) : _dio = Dio(BaseOptions(baseUrl: baseUrl));

  static Future post(String path, Map<String, dynamic> body) {
    return _instance._dio.post(
      path,
      data: body,
      options: Options(contentType: "application/json"),
    );
  }

  static Future get(String path) {
    return _instance._dio.get(path);
  }
}
