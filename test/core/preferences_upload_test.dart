import 'package:cozy_health/core/models/user_preferences.dart';
import 'package:cozy_health/core/models/sync_item.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import '../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<UserPreferences>(LocalDbService.userPreferencesBoxName, UserPreferencesAdapter());
  setUpAll(() async {
    await fixture.open();
    await local.settingsBox();
    await Hive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    await fixture.reset();
    await local.syncQueueBox.clear();
  });
  tearDownAll(fixture.close);

  Future<SyncItem> queue() async {
    await local.saveUserPreferences(UserPreferences(focusAreas: ['Sleep'], currentChallenges: ['Work'], checkInFrequency: 'Daily', completedAt: DateTime.utc(2026, 10, 8), skipped: false));
    return SyncItem.fromJson(local.syncQueueBox.values.single);
  }

  test('preferences upload reaches batch sync and successful acknowledgment drains queue', () async {
    final item = await queue();
    fixture.body = {'data': {'results': [{'client_operation_id': item.id, 'success': true}]}};
    await local.processSyncQueue();
    expect(fixture.requests.single.path, '/api/v1/sync/batch');
    final operation = fixture.requestBodies.single['operations'].single;
    expect(operation['type'], 'user_preferences');
    expect(operation['data']['focus_areas'], ['Sleep']);
    expect(local.syncQueueBox.isEmpty, isTrue);
  });

  test('preferences use the ordinary retry schedule after a failed acknowledgment', () async {
    final item = await queue();
    fixture.body = {'data': {'results': [{'client_operation_id': item.id, 'success': false}]}};
    await local.processSyncQueue();
    final pending = SyncItem.fromJson(local.syncQueueBox.values.single);
    expect(pending.retryCount, 1);
    expect(pending.nextRetryAt, isNotNull);
    await local.processSyncQueue();
    expect(SyncItem.fromJson(local.syncQueueBox.values.single).retryCount, 2);
    await local.processSyncQueue();
    expect(fixture.requests.length, 2);
  });
}
