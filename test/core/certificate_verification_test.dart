import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_transport_io.dart';
import 'package:cozy_health/core/api/api_destination_policy.dart';

const fixture = 'test/fixtures/tls';

void main() {
  late HttpServer server;
  late Dio dio;
  var requests = 0;
  var started = false;

  Future<void> start(
    String name, {
    bool trusted = true,
    bool redirect = false,
  }) async {
    requests = 0;
    final key = name == 'next' ? 'next' : 'current';
    final serverContext = SecurityContext()
      ..useCertificateChain('$fixture/$name.pem')
      ..usePrivateKey('$fixture/$key.key');
    server = await HttpServer.bindSecure(
      InternetAddress.loopbackIPv4,
      0,
      serverContext,
    );
    started = true;
    server.listen((request) async {
      requests++;
      await request.drain<void>();
      if (redirect) {
        request.response.statusCode = 302;
        request.response.headers.set(
          'location',
          'http://localhost:${server.port}/health',
        );
      } else {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"ok":true}');
      }
      await request.response.close();
    }, onError: (Object _) {});
    final clientContext = trusted
        ? (SecurityContext(withTrustedRoots: false)
            ..setTrustedCertificates('$fixture/ca.pem'))
        : null;
    dio =
        Dio(
            BaseOptions(
              headers: {'Authorization': 'Bearer synthetic-test-token'},
            ),
          )
          ..httpClientAdapter = VerifiedApiAdapter(
            ApiDestinationPolicy(host: 'localhost', port: server.port),
            context: clientContext,
          );
  }

  tearDown(() async {
    if (!started) return;
    dio.close(force: true);
    await server.close(force: true);
    started = false;
  });

  for (final name in ['current', 'next']) {
    test(
      '$name trusted certificate accepts a native production login request',
      () async {
        await start(name);
        final response = await dio.post(
          'https://localhost:${server.port}/auth/login',
          data: {'email': 'synthetic@example.test', 'password': 'synthetic'},
        );
        expect(response.statusCode, 200);
        expect(requests, 1);
      },
    );
  }

  test(
    'certificate renewal succeeds through the same verified transport',
    () async {
      await start('current');
      final port = server.port;
      expect((await dio.get('https://localhost:$port/health')).statusCode, 200);
      await server.close(force: true);
      final renewed = SecurityContext()
        ..useCertificateChain('$fixture/next.pem')
        ..usePrivateKey('$fixture/next.key');
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        port,
        renewed,
      );
      server.listen((request) async {
        requests++;
        await request.drain<void>();
        request.response.write('renewed');
        await request.response.close();
      }, onError: (Object _) {});
      expect((await dio.get('https://localhost:$port/health')).statusCode, 200);
      expect(requests, 2);
    },
  );

  for (final name in ['expired', 'wrong-host']) {
    test(
      '$name certificate fails before credentials reach the server',
      () async {
        await start(name);
        await expectLater(
          dio.post(
            'https://localhost:${server.port}/auth/login',
            data: {'password': 'synthetic'},
          ),
          throwsA(isA<DioException>()),
        );
        expect(requests, 0);
      },
    );
  }

  test(
    'untrusted certificate fails before credentials reach the server',
    () async {
      await start('current', trusted: false);
      await expectLater(
        dio.post(
          'https://localhost:${server.port}/auth/login',
          data: {'password': 'synthetic'},
        ),
        throwsA(isA<DioException>()),
      );
      expect(requests, 0);
    },
  );

  test(
    'destination policy rejects cleartext, credentials, other hosts and ports',
    () {
      const policy = ApiDestinationPolicy(host: 'api.cozyhealth.org');
      expect(
        policy.permits(Uri.parse('https://api.cozyhealth.org/api/v1')),
        isTrue,
      );
      for (final value in [
        'http://api.cozyhealth.org/api/v1',
        'https://api.cozyhealth.org.attacker.example/api/v1',
        'https://api.cozyhealth.org:444/api/v1',
        'https://user:secret@api.cozyhealth.org/api/v1',
      ]) {
        expect(policy.permits(Uri.parse(value)), isFalse, reason: value);
      }
    },
  );

  test('invalid destinations are blocked before sending a request', () async {
    await start('current');
    for (final value in [
      'http://localhost:${server.port}/health',
      'https://127.0.0.1:${server.port}/health',
      'https://user:secret@localhost:${server.port}/health',
    ]) {
      await expectLater(dio.get(value), throwsA(isA<DioException>()));
    }
    expect(requests, 0);
  });

  test(
    'redirect is rejected even when request options enable following it',
    () async {
      await start('current', redirect: true);
      await expectLater(
        dio.get(
          'https://localhost:${server.port}/health',
          options: Options(followRedirects: true),
        ),
        throwsA(isA<DioException>()),
      );
      expect(requests, 1);
    },
  );
}
