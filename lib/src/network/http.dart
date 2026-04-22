import 'package:dio/dio.dart';
import 'package:rwkv_studio/src/errors/app_exception.dart';
import 'package:rwkv_studio/src/utils/logger.dart';

typedef HttpDecoder<T> = T Function(dynamic data);

class HTTP {
  static const String defaultBaseUrl = 'http://192.168.0.79:5000';
  static const Duration _defaultConnectTimeout = Duration(seconds: 15);
  static const Duration _defaultSendTimeout = Duration(seconds: 30);
  static const Duration _defaultReceiveTimeout = Duration(seconds: 30);

  static HTTP _instance = HTTP(defaultBaseUrl);

  final Dio _dio;

  HTTP(
    String baseUrl, {
    Duration connectTimeout = _defaultConnectTimeout,
    Duration sendTimeout = _defaultSendTimeout,
    Duration receiveTimeout = _defaultReceiveTimeout,
    Map<String, dynamic> headers = const {},
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: connectTimeout,
           sendTimeout: sendTimeout,
           receiveTimeout: receiveTimeout,
           headers: Map<String, dynamic>.from(headers),
           responseType: ResponseType.json,
         ),
       ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          logi('HTTP -> ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          logi(
            'HTTP <- ${response.statusCode ?? '-'} '
            '${response.requestOptions.method} ${response.requestOptions.uri}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          logw(
            'HTTP xx ${error.requestOptions.method} '
                    '${error.requestOptions.uri} ${error.message ?? ''}'
                .trim(),
          );
          handler.next(error);
        },
      ),
    );
  }

  static Dio get client => _instance._dio;

  static String get baseUrl => _instance._dio.options.baseUrl;

  static void init({
    String baseUrl = defaultBaseUrl,
    Duration connectTimeout = _defaultConnectTimeout,
    Duration sendTimeout = _defaultSendTimeout,
    Duration receiveTimeout = _defaultReceiveTimeout,
    Map<String, dynamic> headers = const {},
  }) {
    _instance = HTTP(
      baseUrl,
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
    );
  }

  static void configure({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? sendTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
    bool mergeHeaders = true,
  }) {
    final options = _instance._dio.options;
    final currentHeaders = Map<String, dynamic>.from(options.headers);
    final nextHeaders = headers == null
        ? currentHeaders
        : mergeHeaders
        ? <String, dynamic>{...currentHeaders, ...headers}
        : Map<String, dynamic>.from(headers);

    _instance = HTTP(
      baseUrl ?? options.baseUrl,
      connectTimeout:
          connectTimeout ?? options.connectTimeout ?? _defaultConnectTimeout,
      sendTimeout: sendTimeout ?? options.sendTimeout ?? _defaultSendTimeout,
      receiveTimeout:
          receiveTimeout ?? options.receiveTimeout ?? _defaultReceiveTimeout,
      headers: nextHeaders,
    );
  }

  static void setHeader(String key, Object? value) {
    _instance._dio.options.headers[key] = value;
  }

  static void removeHeader(String key) {
    _instance._dio.options.headers.remove(key);
  }

  static void clearHeaders() {
    _instance._dio.options.headers.clear();
  }

  static void setBearerToken(String token, {String header = 'Authorization'}) {
    setHeader(header, 'Bearer $token');
  }

  static void clearBearerToken({String header = 'Authorization'}) {
    removeHeader(header);
  }

  static Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) {
    return request<T>(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  static Future<T> post<T>(
    String path,
    dynamic body, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) {
    return request<T>(
      path,
      method: 'POST',
      data: body,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  static Future<T> put<T>(
    String path,
    dynamic body, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) {
    return request<T>(
      path,
      method: 'PUT',
      data: body,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  static Future<T> patch<T>(
    String path,
    dynamic body, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) {
    return request<T>(
      path,
      method: 'PATCH',
      data: body,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  static Future<T> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) {
    return request<T>(
      path,
      method: 'DELETE',
      data: body,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  static Future<T> request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) async {
    final response = await _guard(
      method,
      path,
      () => _instance._dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(
          method: method,
          data: data,
          options: options,
          headers: headers,
        ),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
    );
    return _decode<T>(response.data, decoder);
  }

  static Future<T> requestData<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    HttpDecoder<T>? decoder,
  }) async {
    return request<T>(
      path,
      method: method,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
      decoder: decoder,
    );
  }

  static Future<T> download<T>(
    String path,
    dynamic savePath, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    Options? options,
    dynamic data,
    bool deleteOnError = true,
    HttpDecoder<T>? decoder,
  }) async {
    final response = await _guard(
      'DOWNLOAD',
      path,
      () => _instance._dio.download(
        path,
        savePath,
        data: data,
        queryParameters: queryParameters,
        options: _buildOptions(
          method: 'GET',
          data: data,
          options: options,
          headers: headers,
        ),
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        onReceiveProgress: onReceiveProgress,
      ),
    );
    return _decode<T>(response.data, decoder);
  }

  static Options _buildOptions({
    required String method,
    required dynamic data,
    Options? options,
    Map<String, dynamic>? headers,
  }) {
    final mergedHeaders = <String, dynamic>{...?options?.headers, ...?headers};
    return (options ?? Options()).copyWith(
      method: method,
      headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      contentType: options?.contentType ?? _resolveContentType(data),
    );
  }

  static String? _resolveContentType(dynamic body) {
    if (body == null) {
      return null;
    }
    if (body is FormData) {
      return Headers.multipartFormDataContentType;
    }
    if (body is Map || body is Iterable) {
      return Headers.jsonContentType;
    }
    return null;
  }

  static T _decode<T>(dynamic data, HttpDecoder<T>? decoder) {
    if (decoder != null) {
      return decoder(data);
    }
    return data as T;
  }

  static Future<Response<dynamic>> _guard(
    String method,
    String path,
    Future<Response<dynamic>> Function() action,
  ) async {
    try {
      return await action();
    } catch (e, s) {
      final error = AppException.wrap(e, s);
      if (error.isCancelled) {
        logw('HTTP cancelled: $method $path');
      } else {
        loge(
          'HTTP request failed: $method $path',
          error,
          error.stackTrace ?? s,
        );
      }
      Error.throwWithStackTrace(error, error.stackTrace ?? s);
    }
  }
}
