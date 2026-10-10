import 'dart:async';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'auth_token_service.dart';
import 'api_exceptions.dart';
import '../routing/app_router.dart';
import '../services/local_db_service.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.dio, this.onSessionExpired});
  final Dio? dio;
  final Future<void> Function()? onSessionExpired;
  Future<String?>? _refreshing;
  String? _rotatedFrom;
  final _tokens = TokenStorage();

  Future<String?> _refresh() async {
    final refresh = await _tokens.getRefreshToken();
    if (refresh == null || dio == null) return null;
    try {
      final previous = await _tokens.getToken();
      final response = await dio!.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = response.data['data'];
      if (data is! Map ||
          data['token'] is! String ||
          data['refresh_token'] is! String) {
        return null;
      }
      // A logout while refresh is in flight must not restore the session.
      if (await _tokens.getRefreshToken() != refresh) {
        return null;
      }
      await _tokens.saveToken(
        data['token'],
        stayLoggedIn: !_tokens.isSessionOnly,
      );
      await _tokens.saveRefreshToken(data['refresh_token']);
      _rotatedFrom = previous;
      return data['token'];
    } catch (_) {
      return null;
    }
  }

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
      if (dio != null && err.requestOptions.extra['refreshed'] != true) {
        // Concurrent 401s share one rotation; late 401s use the already updated token.
        final current = await _tokens.getToken();
        final sent = err.requestOptions.headers['Authorization'];
        String? token;
        if (current != null && sent != 'Bearer $current') {
          if (sent != 'Bearer $_rotatedFrom') return handler.next(err);
          token = current;
        } else {
          _refreshing ??= _refresh();
          final pending = _refreshing!;
          token = await pending;
          if (identical(_refreshing, pending)) _refreshing = null;
        }
        if (token != null) {
          try {
            final response = await dio!.fetch(
              err.requestOptions.copyWith(
                headers: {
                  ...err.requestOptions.headers,
                  'Authorization': 'Bearer $token',
                },
                extra: {...err.requestOptions.extra, 'refreshed': true},
              ),
            );
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }
      }
      await AuthTokenService.clearToken();
      // Preserve account-scoped unsynced drafts during reauthentication.
      if (onSessionExpired != null) {
        await onSessionExpired!();
      } else {
        // A sync request must finish before account switching waits for it.
        unawaited(LocalDbService().activateGuestAfterSync());
      }

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

    if (err.type == DioExceptionType.badCertificate) {
      exception = ApiSecureConnectionException();
    } else if (err.type == DioExceptionType.connectionTimeout ||
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
