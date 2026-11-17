import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/repositories/mood_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';

import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  final repository = MoodRepository();
  setUpAll(() async {
    await fixture.open();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    await fixture.reset();
    await LocalDbService().syncQueueBox.clear();
  });
  tearDownAll(fixture.close);

  test(
    'fetch returns the newer offline edit instead of the stale server row',
    () async {
      final entry = MoodEntry.fromJson({
        'id': 'edited',
        'mood': 'calm',
        'intensity': 3,
        'note': 'Offline edit',
        'client_created_at': '2026-10-07T12:00:00Z',
        'client_updated_at': '2026-10-08T12:00:00Z',
      });
      await fixture.box.put(entry.id, entry);
      await LocalDbService().enqueueSync(
        type: 'mood_entry',
        action: 'upsert',
        recordId: entry.id,
        payload: entry.toJson(),
      );
      final retryId = LocalDbService().pendingItems.single.id;
      fixture.body = [
        {
          ...entry.toJson(),
          'note': 'Stale server note',
          'client_updated_at': '2026-10-07T12:00:00Z',
        },
      ];
      expect((await repository.fetchMoodEntries()).single.note, 'Offline edit');
      expect(fixture.box.get(entry.id)?.note, 'Offline edit');
      expect(LocalDbService().pendingItems.single.id, retryId);
    },
  );

  test('fetch cannot resurrect a pending deletion', () async {
    await LocalDbService().enqueueSync(
      type: 'mood_entry',
      action: 'delete',
      recordId: 'deleted',
      payload: null,
    );
    fixture.body = [
      {
        'id': 'deleted',
        'mood': 'calm',
        'intensity': 3,
        'client_updated_at': '2026-10-08T12:00:00Z',
      },
    ];
    expect(await repository.fetchMoodEntries(), isEmpty);
    expect(fixture.box.get('deleted'), isNull);
    expect(LocalDbService().pendingItems.single.action, 'delete');
  });

  for (final shape in ['paginator', 'raw list', 'data list']) {
    test(
      'fetchMoodEntries parses $shape and caches the returned records',
      () async {
        final count = shape == 'raw list' ? 2 : 3;
        final items = List.generate(
          count,
          (index) => <String, dynamic>{
            'id': '$shape-$index',
            'mood': 'good',
            'intensity': 5,
            'title': 'Record $index',
            'quiz_slug': 'wellbeing',
            'quiz_title': 'Wellbeing',
            'client_created_at': '2026-10-07T12:00:00Z',
            'client_updated_at': '2026-10-07T12:00:00Z',
          },
        );
        fixture.body = switch (shape) {
          'paginator' => {
            'data': {'data': items, 'current_page': 1, 'last_page': 1},
          },
          'data list' => {'data': items},
          _ => items,
        };

        final result = await repository.fetchMoodEntries();
        expect(result.map((item) => item.id), items.map((item) => item['id']));
        expect(result, hasLength(count));
        expect(fixture.box.length, count);
        expect(fixture.requests, hasLength(1));
        expect(fixture.requests.single.path, '/api/v1/mood-entries');
      },
    );
  }
}
