import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'auth_token_service.dart';
import 'api_exceptions.dart';
import '../routing/app_router.dart';
import '../services/local_db_service.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      return handler.next(options);
    }

    final token = await AuthTokenService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.endsWith('/auth/google') &&
        !err.requestOptions.path.endsWith('/auth/apple')) {
      await AuthTokenService.clearToken();
      await LocalDbService().clearAllUserData();

      final context = AppRouter.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired. Please log in again."),
          ),
        );
        context.go(AppRouter.login);
      }
    }
    return handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  bool _shouldRedactBody(RequestOptions options) {
    final method = options.method.toUpperCase();
    final path = options.uri.path;

    if (path == '/api/v1/auth/google' ||
        path == '/auth/google' ||
        path == '/api/v1/auth/apple' ||
        path == '/auth/apple' ||
        path == '/api/v1/auth/register' ||
        path == '/api/v1/auth/login' ||
        path == '/api/v1/auth/forgot-password' ||
        path == '/api/v1/auth/reset-password' ||
        path == '/auth/register' ||
        path == '/auth/login' ||
        path == '/auth/forgot-password' ||
        path == '/auth/reset-password' ||
        path == '/api/v1/user/preferences' ||
        path == '/user/preferences' ||
        path == '/api/v1/safety-plan' ||
        path == '/safety-plan') {
      return true;
    }

    if ((path == '/api/v1/user/profile' || path == '/user/profile') &&
        method == 'PATCH') {
      return true;
    }

    if ((path == '/api/v1/mood-entries' || path == '/mood-entries') &&
        (method == 'POST' || method == 'PATCH')) {
      return true;
    }

    if ((path == '/api/v1/journal-entries' || path == '/journal-entries') &&
        (method == 'POST' || method == 'PATCH')) {
      return true;
    }

    return RegExp(r'^(/api/v1)?/conversations/[^/]+/messages$').hasMatch(path);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> ${options.method} ${options.uri}');
      if (options.data != null) {
        if (_shouldRedactBody(options)) {
          debugPrint('Body: <redacted>');
        } else {
          debugPrint('Body: ${options.data}');
        }
      }
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '<-- Error ${err.response?.statusCode} ${err.requestOptions.uri}',
      );
      debugPrint('Message: ${err.message}');
    }
    return handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiException exception;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      exception = ApiTimeoutException();
    } else if (err.type == DioExceptionType.connectionError) {
      exception = ApiNetworkException();
    } else if (err.response != null) {
      final statusCode = err.response!.statusCode;
      final data = err.response!.data;

      if ((err.requestOptions.path.endsWith('/auth/google') ||
              err.requestOptions.path.endsWith('/auth/apple')) &&
          data is Map &&
          data['message'] is String) {
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            type: err.type,
            error: ApiValidationException(
              const {},
              data['message'] as String,
              statusCode: statusCode,
            ),
          ),
        );
      }

      if (statusCode == 401 || statusCode == 403) {
        exception = ApiAuthException(statusCode: statusCode);
      } else if (statusCode == 422) {
        Map<String, List<String>> errors = {};
        if (data is Map && data['errors'] is Map) {
          final details = data['errors'] as Map;
          details.forEach((key, value) {
            if (value is List) {
              errors[key.toString()] = value.map((e) => e.toString()).toList();
            }
          });
        } else if (data is Map &&
            data['error'] != null &&
            data['error']['details'] != null) {
          final details = data['error']['details'];
          if (details is Map) {
            details.forEach((key, value) {
              if (value is List) {
                errors[key.toString()] = value
                    .map((e) => e.toString())
                    .toList();
              }
            });
          }
        }
        final message =
            errors.values.firstOrNull?.firstOrNull ??
            (data is Map ? data['message']?.toString() : null) ??
            'Validation Failed';
        exception = ApiValidationException(
          errors,
          message,
          statusCode: statusCode,
        );
      } else if (statusCode != null && statusCode >= 500) {
        exception = ApiServerException(statusCode: statusCode);
      } else {
        exception = ApiUnknownException(err.message ?? 'Unknown error');
      }
    } else {
      exception = ApiUnknownException(err.message ?? 'Unknown error');
    }

    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
      ),
    );
  }
}
