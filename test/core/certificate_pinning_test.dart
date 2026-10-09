import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_transport_io.dart';
import 'package:cozy_health/core/api/leaf_pin_policy.dart';

const fixture = 'test/fixtures/tls';
String pin(String name) {
  final pem = File('$fixture/$name.pem').readAsStringSync();
  final body = pem
      .split('\n')
      .where((line) => !line.startsWith('-----'))
      .join();
  return sha256.convert(base64Decode(body)).toString();
}

void main() {
  late HttpServer server;
  late Dio dio;
  var requests = 0;
  var started = false;
  Future<void> start(
    String name, {
    bool trusted = true,
    bool mismatch = false,
    bool redirect = false,
  }) async {
    requests = 0;
    final serverContext = SecurityContext()
      ..useCertificateChain('$fixture/$name.pem')
      ..usePrivateKey('$fixture/$name.key');
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
            ..setTrustedCertificates('$fixture/current.pem')
            ..setTrustedCertificates('$fixture/next.pem'))
        : null;
    final policy = LeafPinPolicy(
      host: 'localhost',
      port: server.port,
      current: mismatch ? '0' * 64 : pin('current'),
      next: mismatch ? '1' * 64 : pin('next'),
    );
    dio = Dio(
      BaseOptions(headers: {'Authorization': 'Bearer synthetic-test-token'}),
    )..httpClientAdapter = PinnedApiAdapter(policy, context: clientContext);
  }

  tearDown(() async {
    if (!started) return;
    dio.close(force: true);
    await server.close(force: true);
    started = false;
  });

  test(
    'rotation policy fails closed on missing, duplicate, malformed or absent pins',
    () {
      for (final next in ['', pin('current'), 'malformed']) {
        final policy = LeafPinPolicy(
          host: 'localhost',
          current: pin('current'),
          next: next,
        );
        expect(policy.ready, isFalse);
        expect(policy.accepts([1, 2, 3], 'localhost', 443), isFalse);
      }
      final policy = LeafPinPolicy(
        host: 'localhost',
        current: pin('current'),
        next: pin('next'),
      );
      expect(policy.accepts(null, 'localhost', 443), isFalse);
    },
  );

  for (final name in ['current', 'next']) {
    test(
      '$name leaf succeeds with normal TLS verification and an approved pin',
      () async {
        await start(name);
        final response = await dio.post(
          'https://localhost:${server.port}/health',
          data: {'synthetic': true},
        );
        expect(response.statusCode, 200);
        expect(requests, 1);
      },
    );
  }
  test(
    'trusted but unpinned leaf fails before Authorization or body reaches server',
    () async {
      await start('current', mismatch: true);
      await expectLater(
        dio.post(
          'https://localhost:${server.port}/health',
          data: {'synthetic': true},
        ),
        throwsA(isA<DioException>()),
      );
      expect(requests, 0);
    },
  );
  test(
    'matching leaf does not bypass an untrusted certificate chain',
    () async {
      await start('current', trusted: false);
      await expectLater(
        dio.get('https://localhost:${server.port}/health'),
        throwsA(isA<DioException>()),
      );
      expect(requests, 0);
    },
  );
  test(
    'cleartext and another destination are blocked without sending a request',
    () async {
      await start('current');
      await expectLater(
        dio.get('http://localhost:${server.port}/health'),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        dio.get('https://127.0.0.1:${server.port}/health'),
        throwsA(isA<DioException>()),
      );
      expect(requests, 0);
    },
  );
  test(
    'redirect is not followed even when request options enable it',
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
