import 'package:cozy_health/core/widgets/app_snackbar.dart';
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
        err.requestOptions.extra['skipAuth'] != true &&
        !err.requestOptions.path.endsWith('/auth/google') &&
        !err.requestOptions.path.endsWith('/auth/apple')) {
      await AuthTokenService.clearToken();
      await LocalDbService().clearAllUserData();

      final context = AppRouter.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(
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
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('HTTP request: ${options.method}');
      if (options.data != null) debugPrint('Body: <redacted>');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('HTTP response: ${response.statusCode}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('HTTP failure: ${err.response?.statusCode} ${err.type.name}');
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
