import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_transport_io.dart';
import 'package:cozy_health/core/api/api_destination_policy.dart';
import 'package:cozy_health/core/constants/api_constants.dart';

void main() {
  test(
    'native transport reaches the configured API login validation',
    () async {
      // Opt-in network check: no account credentials, emails or mutations.
      final previousOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      final uri = Uri.parse(ApiConstants.baseUrl);
      final dio =
          Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            )
            ..httpClientAdapter = createApiTransport(
              ApiDestinationPolicy(host: uri.host),
            );
      try {
        final health = await dio.getUri(uri.replace(path: '/up'));
        expect(health.statusCode, 200);
        expect(health.data['status'], 'ok');
        final login = await dio.post(
          '/auth/login',
          data: <String, dynamic>{},
          options: Options(validateStatus: (status) => status == 422),
        );
        expect(login.statusCode, 422);
        expect(login.data['errors'], isA<Map>());
        expect(login.data['errors'], contains('email'));
        expect(login.data['errors'], contains('password'));
      } finally {
        dio.close(force: true);
        HttpOverrides.global = previousOverrides;
      }
    },
    skip: !const bool.fromEnvironment('API_SMOKE_TEST'),
  );
}
