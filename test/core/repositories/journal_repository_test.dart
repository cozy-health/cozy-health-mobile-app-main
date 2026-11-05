import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/repositories/journal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';

import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<JournalEntry>(
    LocalDbService.journalBoxName,
    JournalEntryAdapter(),
  );
  final repository = JournalRepository();
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
      final entry = JournalEntry.fromJson({
        'id': 'edited',
        'type': 'free',
        'body': 'Offline edit',
        'word_count': 2,
        'client_created_at': '2026-10-07T12:00:00Z',
        'client_updated_at': '2026-10-08T12:00:00Z',
      });
      await fixture.box.put(entry.id, entry);
      await LocalDbService().enqueueSync(
        type: 'journal_entry',
        action: 'upsert',
        recordId: entry.id,
        payload: entry.toJson(),
      );
      final retryId = LocalDbService().pendingItems.single.id;
      fixture.body = [
        {
          ...entry.toJson(),
          'body': 'Stale server body',
          'client_updated_at': '2026-10-07T12:00:00Z',
        },
      ];
      expect(
        (await repository.fetchJournalEntries()).single.body,
        'Offline edit',
      );
      expect(fixture.box.get(entry.id)?.body, 'Offline edit');
      expect(LocalDbService().pendingItems.single.id, retryId);
    },
  );

  test('fetch cannot resurrect a pending deletion', () async {
    await LocalDbService().enqueueSync(
      type: 'journal_entry',
      action: 'delete',
      recordId: 'deleted',
      payload: null,
    );
    fixture.body = [
      {
        'id': 'deleted',
        'type': 'free',
        'body': 'Deleted journal',
        'client_updated_at': '2026-10-08T12:00:00Z',
      },
    ];
    expect(await repository.fetchJournalEntries(), isEmpty);
    expect(fixture.box.get('deleted'), isNull);
    expect(LocalDbService().pendingItems.single.action, 'delete');
  });

  test(
    'partial server fields preserve a title while explicit null clears it',
    () async {
      final entry = JournalEntry.fromJson({
        'id': 'partial',
        'type': 'free',
        'title': 'Keep this title',
        'body': 'Original',
        'client_created_at': '2026-10-07T12:00:00Z',
        'client_updated_at': '2026-10-07T12:00:00Z',
      });
      await fixture.box.put(entry.id, entry);
      fixture.body = [
        {
          'id': entry.id,
          'body': 'Remote edit',
          'client_updated_at': '2026-10-08T12:00:00Z',
        },
      ];
      expect(
        (await repository.fetchJournalEntries()).single.title,
        'Keep this title',
      );
      fixture.body = [
        {
          'id': entry.id,
          'title': null,
          'client_updated_at': '2026-10-09T12:00:00Z',
        },
      ];
      final cleared = (await repository.fetchJournalEntries()).single;
      expect(cleared.title, isNull);
      expect(cleared.body, 'Remote edit');
    },
  );

  for (final shape in ['paginator', 'raw list', 'data list']) {
    test(
      'fetchJournalEntries parses $shape and caches the returned records',
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

        final result = await repository.fetchJournalEntries();
        expect(result.map((item) => item.id), items.map((item) => item['id']));
        expect(result, hasLength(count));
        expect(fixture.box.length, count);
        expect(fixture.requests, hasLength(1));
        expect(fixture.requests.single.path, '/api/v1/journal-entries');
      },
    );
  }
}
