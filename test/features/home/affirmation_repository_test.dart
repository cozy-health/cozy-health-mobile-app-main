import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/models/affirmation_assignment.dart';
import 'package:cozy_health/core/repositories/affirmation_repository.dart';
import 'package:cozy_health/core/repositories/endpoint_cache.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/endpoint_fixture.dart';

class DeferredAffirmationTransport implements HttpClientAdapter {
  final started = Completer<void>();
  final response = Completer<ResponseBody>();
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) {
    started.complete();
    return response.future;
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  late DateTime now;
  late EndpointCache cache;
  late AffirmationRepository repository;
  Map<String, dynamic> assignment({int id = 1, DateTime? assigned}) {
    final start = assigned ?? DateTime.utc(2026, 10, 8, 14, 30);
    return {
      'id': id,
      'body': 'Affirmation $id',
      'date': '2026-10-08',
      'assigned_at': start.toIso8601String(),
      'expires_at': start.add(const Duration(hours: 24)).toIso8601String(),
    };
  }

  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    now = DateTime.utc(2026, 10, 8, 14, 30);
    cache = EndpointCache(now: () => now);
    repository = AffirmationRepository(cache: cache, now: () => now);
    fixture.body = {'success': true, 'data': assignment()};
  });
  tearDownAll(fixture.close);

  test(
    'stores a server assignment with exact expiry in the scoped cache',
    () async {
      expect(await repository.cached(), isNull);
      final value = await repository.fetchCurrent();
      expect(value!.body, 'Affirmation 1');
      expect(value.expiresAt, DateTime.utc(2026, 10, 9, 14, 30));
      expect(fixture.requests.single.path, '/api/v1/affirmations/today');
      expect(fixture.box.keys, contains('1:affirmation_assignment_v1'));
    },
  );
  test('cache survives midnight, five-minute TTL, and cold restart', () async {
    await repository.fetchCurrent();
    now = now.add(const Duration(hours: 20));
    await fixture.box.close();
    final cold = AffirmationRepository(cache: cache, now: () => now);
    expect((await cold.fetchCurrent())!.body, 'Affirmation 1');
    fixture.box = EncryptedHive.box<String>(EndpointCache.boxName);
    expect(fixture.requests, hasLength(1));
  });
  test(
    'exact expiry invalidates cache and obtains next server assignment',
    () async {
      await repository.fetchCurrent();
      now = now.add(const Duration(hours: 24));
      expect(await repository.cached(), isNull);
      expect(
        (await repository.cached(allowExpired: true))!.body,
        'Affirmation 1',
      );
      fixture.body = {'data': assignment(id: 2, assigned: now)};
      expect((await repository.fetchCurrent())!.body, 'Affirmation 2');
      expect(fixture.requests, hasLength(2));
    },
  );
  test(
    'force refresh can replace an unexpired but disabled assignment',
    () async {
      await repository.fetchCurrent();
      fixture.body = {'data': assignment(id: 2)};
      expect((await repository.fetchCurrent(force: true))!.id, 2);
    },
  );
  test(
    'network failure keeps last saved assignment for offline display',
    () async {
      await repository.fetchCurrent();
      now = now.add(const Duration(days: 2));
      fixture.body = {'unexpected': 'response'};
      await expectLater(repository.fetchCurrent(), throwsFormatException);
      expect(
        (await repository.cached(allowExpired: true))!.body,
        'Affirmation 1',
      );
    },
  );
  test(
    'empty catalog clears stale content but does not negative-cache for 24 hours',
    () async {
      await repository.fetchCurrent();
      fixture.body = {'data': null};
      expect(await repository.fetchCurrent(force: true), isNull);
      expect(await repository.cached(allowExpired: true), isNull);
      fixture.body = {'data': assignment(id: 2)};
      expect((await repository.fetchCurrent())!.id, 2);
    },
  );
  test(
    'cache is isolated between login sessions and old date caches are ignored',
    () async {
      await repository.fetchCurrent();
      await TokenStorage().saveToken('2|other');
      expect(await repository.cached(allowExpired: true), isNull);
      await cache.write('affirmation_2026-10-08', {
        'date': '2026-10-08',
        'body': 'Old copy',
      }, await cache.owner());
      expect(await repository.cached(), isNull);
      expect((await repository.fetchCurrent())!.body, 'Affirmation 1');
    },
  );
  test('guests do not call the authenticated endpoint', () async {
    await TokenStorage().clearToken();
    expect(await repository.fetchCurrent(), isNull);
    expect(fixture.requests, isEmpty);
  });
  test(
    'malformed assignments are rejected without overwriting a valid cache',
    () async {
      await repository.fetchCurrent();
      for (final bad in [
        {},
        {...assignment(), 'body': ''},
        {...assignment(), 'id': '1'},
        {...assignment(), 'expires_at': 'invalid'},
        {...assignment(), 'expires_at': now.toIso8601String()},
      ]) {
        fixture.body = {'data': bad};
        await expectLater(
          repository.fetchCurrent(force: true),
          throwsFormatException,
        );
        expect((await repository.cached())!.body, 'Affirmation 1');
      }
    },
  );
  test(
    'UTC assignment duration remains 24 hours across timezone and DST changes',
    () async {
      final value = AffirmationAssignment.fromJson(
        assignment(assigned: DateTime.utc(2026, 11, 1, 4)),
      );
      expect(
        value.expiresAt.difference(value.assignedAt),
        const Duration(hours: 24),
      );
      expect(value.isExpired(DateTime.utc(2026, 11, 2, 3, 59)), isFalse);
      expect(value.isExpired(DateTime.utc(2026, 11, 2, 4)), isTrue);
    },
  );
  test(
    'real repository ignores a delayed HTTP response after session switching',
    () async {
      await repository.fetchCurrent();
      final previous = ApiClient().transportForTesting;
      final delayed = DeferredAffirmationTransport();
      ApiClient().transportForTesting = delayed;
      try {
        final work = repository.fetchCurrent(force: true);
        await delayed.started.future;
        await TokenStorage().saveToken('2|other');
        delayed.response.complete(
          ResponseBody.fromString(
            jsonEncode({'data': assignment(id: 2)}),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        );
        await expectLater(work, throwsStateError);
        expect(await repository.cached(allowExpired: true), isNull);
        expect(fixture.box.get('2:affirmation_assignment_v1'), isNull);
      } finally {
        ApiClient().transportForTesting = previous;
      }
    },
  );
}
