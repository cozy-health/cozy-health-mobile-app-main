import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/storage/token_storage.dart';

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
  test('concurrent 401 responses share one refresh and retry once', () async {
    final tokens = TokenStorage();
    await tokens.saveToken('old');
    await tokens.saveRefreshToken('refresh-old');
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
    await tokens.saveRefreshToken('refresh');
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
      await tokens.saveRefreshToken('refresh');
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
}
