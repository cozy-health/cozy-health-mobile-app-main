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
import '../services/age_eligibility_service.dart';
import '../services/consent_refresh_signal.dart';
import '../storage/token_storage.dart';

typedef _RefreshedSession = ({String token, int generation});

class AuthInterceptor extends Interceptor {
  AuthInterceptor({this.dio, this.onSessionExpired});
  final Dio? dio;
  final Future<void> Function()? onSessionExpired;
  Future<_RefreshedSession?>? _refreshing;
  String? _rotatedFrom;
  int? _rotatedFromGeneration, _rotatedGeneration;
  final _tokens = TokenStorage();

  Future<_RefreshedSession?> _refresh() async {
    final generation = TokenStorage.generation;
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
      final storedRefresh = await _tokens.getRefreshToken();
      if (generation != TokenStorage.generation || storedRefresh != refresh) {
        return null;
      }
      final installedGeneration = await _tokens.saveSession(
        data['token'],
        refreshToken: data['refresh_token'],
        stayLoggedIn: !_tokens.isSessionOnly,
      );
      if (TokenStorage.generation != installedGeneration) return null;
      _rotatedFrom = previous;
      _rotatedFromGeneration = generation;
      _rotatedGeneration = installedGeneration;
      return (token: data['token'] as String, generation: installedGeneration);
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

    final generation = TokenStorage.generation;
    final expected = options.extra['expectedSessionGeneration'];
    if (expected != null && expected != generation) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: 'The original session ended',
        ),
      );
    }
    final token = await AuthTokenService.getToken();
    if (generation != TokenStorage.generation) {
      return handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.cancel),
      );
    }
    options.extra['sessionGeneration'] = generation;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final generation = response.requestOptions.extra['sessionGeneration'];
    if (generation != null && generation != TokenStorage.generation) {
      return handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.cancel,
          error: 'Session ended',
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final origin = err.requestOptions.extra['sessionGeneration'];
    final currentRotation =
        origin == _rotatedFromGeneration &&
        TokenStorage.generation == _rotatedGeneration &&
        err.requestOptions.headers['Authorization'] == 'Bearer $_rotatedFrom';
    if (err.requestOptions.extra['sessionGeneration'] != null &&
        err.requestOptions.extra['sessionGeneration'] !=
            TokenStorage.generation &&
        !currentRotation) {
      return handler.next(err);
    }
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['skipAuth'] != true &&
        !err.requestOptions.path.endsWith('/auth/google') &&
        !err.requestOptions.path.endsWith('/auth/apple')) {
      if (dio != null && err.requestOptions.extra['refreshed'] != true) {
        // Concurrent 401s share one rotation; late 401s use the already updated token.
        final current = await _tokens.getToken();
        final sent = err.requestOptions.headers['Authorization'];
        _RefreshedSession? renewed;
        if (current != null && sent != 'Bearer $current') {
          if (sent != 'Bearer $_rotatedFrom' ||
              origin != _rotatedFromGeneration ||
              TokenStorage.generation != _rotatedGeneration) {
            return handler.next(err);
          }
          renewed = (token: current, generation: TokenStorage.generation);
        } else {
          _refreshing ??= _refresh();
          final pending = _refreshing!;
          renewed = await pending;
          if (identical(_refreshing, pending)) _refreshing = null;
        }
        if (renewed != null) {
          if (renewed.generation != TokenStorage.generation) {
            return handler.next(err);
          }
          try {
            final response = await dio!.fetch(
              err.requestOptions.copyWith(
                headers: {
                  ...err.requestOptions.headers,
                  'Authorization': 'Bearer ${renewed.token}',
                },
                extra: {
                  ...err.requestOptions.extra,
                  'refreshed': true,
                  'expectedSessionGeneration': renewed.generation,
                },
              ),
            );
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        }
      }
      // An awaited refresh may have finished after logout or another login.
      // Only its original session may be cleared or redirected.
      if (origin != null && origin != TokenStorage.generation) {
        return handler.next(err);
      }
      final clearedGeneration = TokenStorage.generation + 1;
      await AuthTokenService.clearToken();
      if (TokenStorage.generation != clearedGeneration) {
        return handler.next(err);
      }
      // Preserve account-scoped unsynced drafts during reauthentication.
      if (onSessionExpired != null) {
        await onSessionExpired!();
      } else {
        // A sync request must finish before account switching waits for it.
        unawaited(LocalDbService().activateGuestAfterSync());
      }

      if (TokenStorage.generation != clearedGeneration) {
        return handler.next(err);
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
    final payload = err.response?.data;
    if (payload is Map &&
        payload['code'] == 'consent_required' &&
        err.response?.statusCode == 403 &&
        err.requestOptions.extra['sessionGeneration'] ==
            TokenStorage.generation) {
      consentRefreshSignal.value++;
    }
    if (payload is Map &&
        err.requestOptions.extra['sessionGeneration'] ==
            TokenStorage.generation &&
        payload['eligibility'] is Map &&
        err.response?.statusCode == 403) {
      AgeEligibilityService.instance.restricted(
        Map<String, dynamic>.from(payload['eligibility'] as Map),
      );
    }
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

      if ({
            '/me/age',
            '/me/residence',
            '/me/guardian',
            '/me/age-support',
          }.any((path) => err.requestOptions.path.endsWith(path)) &&
          statusCode != 401) {
        final fields = <String, List<String>>{};
        if (statusCode == 422 && data is Map && data['errors'] is Map) {
          for (final entry in (data['errors'] as Map).entries) {
            if (entry.value is List) {
              fields[entry.key.toString()] = (entry.value as List)
                  .whereType<String>()
                  .where((value) => value.length <= 300)
                  .toList();
            }
          }
        }
        final retry = int.tryParse(
          err.response?.headers.value('retry-after') ??
              (data is Map ? '${data['retry_after'] ?? ''}' : ''),
        );
        exception = ApiAgeActionException(
          statusCode: statusCode,
          fieldErrors: fields,
          code: data is Map && data['code'] is String
              ? data['code'] as String
              : null,
          retryAfterSeconds: retry != null && retry > 0 && retry <= 86400
              ? retry
              : null,
        );
      } else if (statusCode == 403 &&
          data is Map &&
          data['code'] == 'plan_required') {
        exception = ApiValidationException(
          const {},
          data['message'] as String? ??
              'An eligible active plan is needed for this action.',
          statusCode: 403,
        );
      } else if (statusCode == 401 || statusCode == 403) {
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
        exception = ApiUnknownException(
          'Request unavailable',
          statusCode: statusCode,
        );
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
