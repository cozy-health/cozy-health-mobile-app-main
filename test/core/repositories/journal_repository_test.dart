import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/repositories/journal_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<JournalEntry>(
    LocalDbService.journalBoxName,
    JournalEntryAdapter(),
  );
  final repository = JournalRepository();
  setUpAll(fixture.open);
  setUp(fixture.reset);
  tearDownAll(fixture.close);

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
