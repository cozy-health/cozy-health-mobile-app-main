import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/usage_analytics.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../support/repository_fixture.dart';
import '../support/mobile_sync_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<SubscriptionStatus>(
    LocalDbService.subscriptionStatusBoxName,
    SubscriptionStatusAdapter(),
  );
  final requests = <RequestOptions>[];
  final client = Dio();
  final analytics = UsageAnalytics.forTesting(
    client: client,
    apiKey: 'phc_fixture',
    collector: 'https://us.i.posthog.com',
  );
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Cozy',
      packageName: 'cozy.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'fixture',
    );
    await fixture.open();
    registerSyncAdapters();
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(requestOptions: options, data: {}, statusCode: 200),
          );
        },
      ),
    );
  });
  setUp(() async {
    analytics.reset();
    await local.activateAccount('analytics-fixture');
    final box = await local.settingsBox();
    await box.clear();
    analytics.routeChanged('/settings');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    requests.clear();
  });
  tearDownAll(() async {
    analytics.reset();
    await local.waitForSyncIdle();
    client.close(force: true);
    await fixture.close();
  });

  test(
    'consent gates an allowlisted content-free event and opt-out deletes identity',
    () async {
      await analytics.track('feature_opened', feature: 'settings');
      expect(requests, isEmpty);
      final box = await local.settingsBox();
      await box.put('privacy_preferences', {
        'analytics': true,
        'private_health': 'DO_NOT_SEND',
      });
      await analytics.track('feature_opened', feature: 'settings');
      expect(requests, hasLength(1));
      expect(
        requests.single.uri.toString(),
        'https://us.i.posthog.com/i/v0/e/',
      );
      final properties = (requests.single.data as Map)['properties'] as Map;
      expect(properties.keys.toSet(), {
        'distinct_id',
        'platform',
        'app_version',
        'environment',
        'feature',
        r'$process_person_profile',
        r'$geoip_disable',
      });
      expect(properties['environment'], 'development');
      expect(properties[r'$process_person_profile'], isFalse);
      expect(properties[r'$geoip_disable'], isTrue);
      expect(requests.single.data.toString(), isNot(contains('DO_NOT_SEND')));
      await box.put('privacy_preferences', {'analytics': false});
      await analytics.preferenceChanged(false);
      expect(box.get('posthog_distinct_id'), isNull);
      await analytics.track('feature_opened', feature: 'settings');
      expect(requests, hasLength(1));
    },
  );

  test(
    'private routes, unknown events and a different account do not inherit consent',
    () async {
      await (await local.settingsBox()).put('privacy_preferences', {
        'analytics': true,
      });
      analytics.routeChanged('/safety-plan');
      await analytics.track('feature_opened', feature: 'settings');
      expect(requests, isEmpty);
      analytics.routeChanged('/settings');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      requests.clear();
      await analytics.track('crisis_opened');
      await analytics.track('feature_opened', feature: 'private_health');
      expect(requests, isEmpty);
      await local.activateAccount('analytics-other-fixture');
      await analytics.track('feature_opened', feature: 'settings');
      expect(requests, isEmpty);
    },
  );

  test(
    'production event labeling preserves consent and private-route checks',
    () async {
      final production = UsageAnalytics.forTesting(
        client: client,
        apiKey: 'phc_fixture',
        collector: 'https://us.i.posthog.com',
        environment: 'production',
      );
      production.routeChanged('/settings');
      await production.track('feature_opened', feature: 'settings');
      expect(requests, isEmpty);
      await (await local.settingsBox()).put('privacy_preferences', {
        'analytics': true,
      });
      await production.track('feature_opened', feature: 'settings');
      expect(requests, hasLength(1));
      expect(
        ((requests.single.data as Map)['properties'] as Map)['environment'],
        'production',
      );
      production.routeChanged('/safety-plan');
      await production.track('feature_opened', feature: 'settings');
      expect(requests, hasLength(1));
      production.reset();
    },
  );

  test('analytics network failure is swallowed without retry', () async {
    await (await local.settingsBox()).put('privacy_preferences', {
      'analytics': true,
    });
    final broken = Dio();
    var attempts = 0;
    broken.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          attempts++;
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
            ),
          );
        },
      ),
    );
    final failing = UsageAnalytics.forTesting(
      client: broken,
      apiKey: 'phc_fixture',
      collector: 'https://us.i.posthog.com',
    );
    failing.routeChanged('/create-account');
    await failing.track('signup_started');
    expect(attempts, 1);
    broken.close(force: true);
  });
}
