import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'a public config 401 cannot clear the saved session or local data',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      await TokenStorage().saveToken('test-session');
      final dio = Dio()..httpClientAdapter = _UnauthorizedAdapter();
      dio.interceptors.add(AuthInterceptor());
      await expectLater(
        dio.get(
          'https://example.org/config',
          options: Options(extra: {'skipAuth': true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(await TokenStorage().getToken(), 'test-session');
      dio.close();
    },
  );
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{}',
    401,
    headers: {
      'content-type': ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}
