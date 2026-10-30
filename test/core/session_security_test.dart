import 'package:cozy_health/core/api/api_exceptions.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/services/consent_refresh_signal.dart';

class Adapter implements HttpClientAdapter {
  Adapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody json(String value, int status) => ResponseBody.fromString(
  value,
  status,
  headers: {
    'content-type': ['application/json'],
  },
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clearToken();
  });
  test('an old failed refresh cannot sign out the next account', () async {
    final tokens = TokenStorage();
    await tokens.saveSession('account-a', refreshToken: 'refresh-a');
    final entered = Completer<void>();
    final release = Completer<ResponseBody>();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = Adapter((request) async {
      if (request.path == '/auth/refresh') {
        entered.complete();
        return release.future;
      }
      return json('{}', 401);
    });
    dio.interceptors.add(
      AuthInterceptor(dio: dio, onSessionExpired: () async {}),
    );
    final failed = expectLater(dio.get('/me'), throwsA(isA<DioException>()));
    await entered.future;
    await tokens.saveSession('account-b', refreshToken: 'refresh-b');
    release.complete(json('{}', 401));
    await failed;
    expect(await tokens.getToken(), 'account-b');
    expect(await tokens.getRefreshToken(), 'refresh-b');
    dio.close();
  });

  test(
    'a retry bound to an earlier session never transmits as the next account',
    () async {
      final tokens = TokenStorage();
      await tokens.saveToken('account-a');
      final earlier = TokenStorage.generation;
      await tokens.saveToken('account-b');
      var transmitted = false;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = Adapter((_) async {
        transmitted = true;
        return json('{}', 200);
      });
      dio.interceptors.add(
        AuthInterceptor(dio: dio, onSessionExpired: () async {}),
      );
      await expectLater(
        dio.post(
          '/journals',
          data: {'body': 'account-a draft'},
          options: Options(extra: {'expectedSessionGeneration': earlier}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(transmitted, false);
      expect(await tokens.getToken(), 'account-b');
      dio.close();
    },
  );
  test(
    'only current-session consent denials request a consent recheck',
    () async {
      final before = consentRefreshSignal.value;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = Adapter(
        (_) async => json('{"code":"consent_required"}', 403),
      );
      dio.interceptors.add(ErrorInterceptor());
      await expectLater(
        dio.get(
          '/mood-entries',
          options: Options(
            extra: {'sessionGeneration': TokenStorage.generation - 1},
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(consentRefreshSignal.value, before);
      await expectLater(
        dio.get(
          '/mood-entries',
          options: Options(
            extra: {'sessionGeneration': TokenStorage.generation},
          ),
        ),
        throwsA(isA<DioException>()),
      );
      expect(consentRefreshSignal.value, before + 1);
      dio.close();
    },
  );
  test('concurrent 401 responses share one refresh and retry once', () async {
    final tokens = TokenStorage();
    await tokens.saveToken('old');
    await tokens.saveRefreshToken(
      'refresh-old',
      expectedGeneration: TokenStorage.generation,
    );
    var refreshes = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = Adapter((request) async {
      if (request.path == '/auth/refresh') {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return json(
          '{"data":{"token":"new","refresh_token":"refresh-new"}}',
          200,
        );
      }
      return request.headers['Authorization'] == 'Bearer new'
          ? json('{}', 200)
          : json('{}', 401);
    });
    dio.interceptors.add(
      AuthInterceptor(dio: dio, onSessionExpired: () async {}),
    );
    final responses = await Future.wait([dio.get('/me'), dio.get('/me')]);
    expect(responses.map((r) => r.statusCode), [200, 200]);
    expect(refreshes, 1);
    expect(await tokens.getRefreshToken(), 'refresh-new');
    dio.close();
  });
  test('failed refresh clears both credentials and calls logout', () async {
    final tokens = TokenStorage();
    await tokens.saveToken('old');
    await tokens.saveRefreshToken(
      'refresh',
      expectedGeneration: TokenStorage.generation,
    );
    var loggedOut = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = Adapter((_) async => json('{}', 401));
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        onSessionExpired: () async {
          loggedOut++;
        },
      ),
    );
    await expectLater(dio.get('/me'), throwsA(isA<DioException>()));
    expect(loggedOut, 1);
    expect(await tokens.getToken(), isNull);
    expect(await tokens.getRefreshToken(), isNull);
    dio.close();
  });
  test(
    'session-only refresh is never persisted and logout clears it',
    () async {
      final tokens = TokenStorage();
      await tokens.saveToken('access', stayLoggedIn: false);
      await tokens.saveRefreshToken(
        'refresh',
        expectedGeneration: TokenStorage.generation,
      );
      expect(await tokens.getRefreshToken(), 'refresh');
      expect(
        await const FlutterSecureStorage().read(
          key: 'cozy_health_refresh_token',
        ),
        isNull,
      );
      await tokens.clearToken();
      expect(await tokens.getRefreshToken(), isNull);
    },
  );
  test(
    'normal inactivity expires at thirty days, sensitive at five minutes',
    () async {
      final tokens = TokenStorage(), now = DateTime.utc(2026, 10, 9);
      await tokens.recordActivity(now);
      expect(
        await tokens.inactivityExpired(
          sensitive: false,
          now: now.add(const Duration(days: 29)),
        ),
        false,
      );
      expect(
        await tokens.inactivityExpired(
          sensitive: false,
          now: now.add(const Duration(days: 30)),
        ),
        true,
      );
      expect(
        await tokens.inactivityExpired(
          sensitive: true,
          now: now.add(const Duration(minutes: 4)),
        ),
        false,
      );
      expect(
        await tokens.inactivityExpired(
          sensitive: true,
          now: now.add(const Duration(minutes: 5)),
        ),
        true,
      );
    },
  );
  test(
    'new device ID persists across sessions without using personal data',
    () async {
      final tokens = TokenStorage();
      final first = await tokens.deviceId();
      await tokens.clearToken();
      expect(await tokens.deviceId(), first);
      expect(first.length, 36);
    },
  );
  test(
    'security re-verification clears current credentials without a refresh loop',
    () async {
      final tokens = TokenStorage();
      await tokens.saveSession('account-a', refreshToken: 'refresh-a');
      var refreshes = 0, expired = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = Adapter((request) async {
        if (request.path == '/auth/refresh') {
          refreshes++;
        }
        return json('{"code":"signin_verification_required"}', 403);
      });
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          onSessionExpired: () async {
            expired++;
          },
        ),
      );
      await expectLater(dio.get('/me'), throwsA(isA<DioException>()));
      expect(refreshes, 0);
      expect(expired, 1);
      expect(await tokens.getToken(), isNull);
      expect(await tokens.getRefreshToken(), isNull);
      dio.close();
    },
  );
  test(
    'a late security denial cannot clear or redirect the next account',
    () async {
      final tokens = TokenStorage();
      await tokens.saveSession('account-a', refreshToken: 'refresh-a');
      final entered = Completer<void>();
      final release = Completer<ResponseBody>();
      var expired = 0;
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = Adapter((request) async {
        entered.complete();
        return release.future;
      });
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          onSessionExpired: () async {
            expired++;
          },
        ),
      );
      final rejected = expectLater(
        dio.get('/me'),
        throwsA(isA<DioException>()),
      );
      await entered.future;
      await tokens.saveSession('account-b', refreshToken: 'refresh-b');
      release.complete(json('{"code":"signin_verification_required"}', 403));
      await rejected;
      expect(expired, 0);
      expect(await tokens.getToken(), 'account-b');
      expect(await tokens.getRefreshToken(), 'refresh-b');
      dio.close();
    },
  );
  for (final entry in {'120': 120, '-1': 60, '999999': 60}.entries) {
    test('challenge Retry-After is bounded for header ${entry.key}', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = Adapter(
        (request) async => ResponseBody.fromString(
          '{}',
          429,
          headers: {
            'content-type': ['application/json'],
            'retry-after': [entry.key],
          },
        ),
      );
      dio.interceptors.add(ErrorInterceptor());
      await expectLater(
        dio.post('/auth/challenge/verify'),
        throwsA(
          isA<DioException>().having(
            (error) => error.error,
            'typed cooldown',
            isA<ApiRateLimitException>().having(
              (error) => error.retryAfterSeconds,
              'seconds',
              entry.value,
            ),
          ),
        ),
      );
      dio.close();
    });
  }
}
