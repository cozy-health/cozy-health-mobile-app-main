import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'api_exceptions.dart';
import 'api_interceptors.dart';

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  late Dio _dio;

  factory ApiClient() {
    return instance;
  }

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    return await _request(
      () => _dio.get(
        path,
        queryParameters: queryParameters ?? query,
        options: _options(options, withAuth),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    return await _request(
      () => _dio.post(
        path,
        data: data ?? body,
        queryParameters: queryParameters,
        options: _options(options, withAuth),
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    return await _request(
      () => _dio.patch(
        path,
        data: data ?? body,
        queryParameters: queryParameters,
        options: _options(options, withAuth),
      ),
    );
  }

  Future<dynamic> put(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    return await _request(
      () => _dio.put(
        path,
        data: data ?? body,
        queryParameters: queryParameters,
        options: _options(options, withAuth),
      ),
    );
  }

  Future<dynamic> delete(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    return await _request(
      () => _dio.delete(
        path,
        data: data ?? body,
        queryParameters: queryParameters,
        options: _options(options, withAuth),
      ),
    );
  }

  Options? _options(Options? options, bool withAuth) {
    if (withAuth) return options;

    final extra = Map<String, dynamic>.from(options?.extra ?? const {});
    extra['skipAuth'] = true;

    return (options ?? Options()).copyWith(extra: extra);
  }

  Future<dynamic> _request(Future<Response> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) throw error;
      rethrow;
    }
  }
}
