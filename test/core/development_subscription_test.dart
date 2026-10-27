import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/settings/data/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';
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
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    registerSyncAdapters();
  });
  tearDownAll(() async {
    await local.waitForSyncIdle();
    await fixture.close();
  });
  test(
    'grant replaces current cache and revocation restores genuine status',
    () async {
      await local.activateAccount('test-owner');
      await TokenStorage().saveToken('fixture-token');
      final real = SubscriptionStatus.fromJson({
        'id': 'store-id',
        'plan': 'standard',
        'status': 'active',
      });
      await local.saveSubscriptionStatus(real);
      fixture.body = {
        'data': {
          'id': 'grant-id',
          'plan': 'student',
          'status': 'active',
          'source': 'development_test',
          'expires_at': DateTime.now()
              .add(const Duration(days: 1))
              .toUtc()
              .toIso8601String(),
        },
      };
      final repo = SubscriptionRepository();
      expect((await repo.fetchSubscription())?.isDevelopmentTest, true);
      expect(local.getSubscriptionStatus()?.tier, 'student');
      expect(local.subscriptionStatusBox.length, 1);
      fixture.body = {'data': real.toJson()};
      expect((await repo.fetchSubscription())?.id, 'store-id');
      expect(local.getSubscriptionStatus()?.isDevelopmentTest, false);
      expect(local.subscriptionStatusBox.length, 1);
      await local.activateAccount('another-owner');
      expect(local.getSubscriptionStatus(), isNull);
      await local.activateAccount('test-owner');
      expect(local.getSubscriptionStatus()?.id, 'store-id');
    },
  );
  test('expired test access is inactive and legacy JSON has no test label', () {
    final expired = SubscriptionStatus.fromJson({
      'id': 'expired',
      'status': 'active',
      'plan': 'premium',
      'source': 'development_test',
      'expires_at': '2000-01-01T00:00:00Z',
    });
    expect(expired.isActive, false);
    expect(expired.isDevelopmentTest, true);
    expect(
      SubscriptionStatus.fromJson({
        'plan': 'standard',
        'status': 'active',
      }).isDevelopmentTest,
      false,
    );
  });
}
