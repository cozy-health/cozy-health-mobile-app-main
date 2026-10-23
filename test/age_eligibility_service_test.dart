import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/services/age_eligibility_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/storage/token_storage.dart';

void main() {
  tearDown(() => networkOffline.value = null);
  test(
    'a pre-enforcement response cannot grant access after staged enforcement turns on',
    () async {
      networkOffline.value = false;
      var enforced = false;
      final service = AgeEligibilityService(
        enforcement: () => enforced,
        token: () async => 'adult',
        fetch: () async => {
          'owner_id': 2,
          'allowed': true,
          'enforced': enforced,
          'online_required': false,
          'age_band': 'adult',
        },
      );
      await service.refresh();
      enforced = true;
      expect(service.blocked, isTrue);
      await service.requirePrivateAccess();
      expect(service.blocked, isFalse);
    },
  );
  test(
    'a rejected request from a previous session cannot change current eligibility',
    () async {
      final service = AgeEligibilityService.instance;
      service.current = const AgeEligibilityState({
        'owner_id': 2,
        'allowed': true,
        'enforced': true,
        'online_required': false,
        'age_band': 'adult',
      });
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'));
      dio.httpClientAdapter = _OldSessionRejection();
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
      expect(service.current?.data['owner_id'], 2);
      expect(service.current?.allowed, isTrue);
      service.current = null;
      dio.close(force: true);
    },
  );
  test('a minor never receives an offline private-feature allowance', () async {
    networkOffline.value = false;
    final service = AgeEligibilityService(
      enforcement: () => true,
      token: () async => 'owner-a',
      fetch: () async => {
        'owner_id': 1,
        'allowed': true,
        'enforced': true,
        'online_required': true,
        'age_band': 'minor',
      },
    );
    await service.refresh();
    expect(service.blocked, isFalse);
    networkOffline.value = true;
    expect(service.blocked, isTrue);
    await expectLater(service.requirePrivateAccess(), throwsStateError);
  });
  test(
    'a failed eligibility check does not retain minor authorization',
    () async {
      networkOffline.value = false;
      var fail = false;
      final service = AgeEligibilityService(
        enforcement: () => true,
        token: () async => 'owner-a',
        fetch: () async {
          if (fail) throw StateError('Offline');
          return {
            'owner_id': 1,
            'allowed': true,
            'enforced': true,
            'online_required': true,
            'age_band': 'minor',
          };
        },
      );
      await service.refresh();
      fail = true;
      await service.refresh();
      expect(service.current, isNull);
      expect(service.blocked, isTrue);
    },
  );
  test(
    'a delayed response cannot reopen another account or paused session',
    () async {
      networkOffline.value = false;
      var owner = 'owner-a';
      final result = Completer<Map<String, dynamic>>();
      final service = AgeEligibilityService(
        enforcement: () => true,
        token: () async => owner,
        fetch: () => result.future,
      );
      final loading = service.refresh();
      await Future<void>.delayed(Duration.zero);
      owner = 'owner-b';
      service.invalidate();
      result.complete({
        'owner_id': 1,
        'allowed': true,
        'enforced': true,
        'online_required': true,
        'age_band': 'minor',
      });
      await loading;
      expect(service.current, isNull);
      expect(service.blocked, isTrue);
    },
  );
  test(
    'adults retain the existing offline allowance and restrictions still win',
    () async {
      networkOffline.value = false;
      final service = AgeEligibilityService(
        enforcement: () => true,
        token: () async => 'adult',
        fetch: () async => {
          'owner_id': 2,
          'allowed': true,
          'enforced': true,
          'online_required': false,
          'age_band': 'adult',
        },
      );
      await service.refresh();
      networkOffline.value = true;
      expect(service.blocked, isFalse);
      service.restricted({
        'allowed': false,
        'online_required': true,
        'reason': 'age_disputed',
      });
      expect(service.blocked, isTrue);
    },
  );
}

class _OldSessionRejection implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"message":"Restricted","eligibility":{"owner_id":1,"allowed":false,"online_required":true,"age_band":"minor"}}',
    403,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}
