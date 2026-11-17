import 'dart:async';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/data/placeholder_data.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/repositories/mood_repository.dart';
import 'package:cozy_health/core/repositories/journal_repository.dart';
import 'package:cozy_health/features/content/data/content_repository.dart';
import 'package:cozy_health/features/notifications/data/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final demo = DemoMode.instance;
  setUp(() => demo.enabled = true);
  tearDown(() {
    demo.enabled = false;
    demo.moods
      ..clear()
      ..addAll(PlaceholderData.moods());
    demo.journals
      ..clear()
      ..addAll(PlaceholderData.journals());
    demo.notifications
      ..clear()
      ..addAll(PlaceholderData.notifications());
    demo.savedArticles.clear();
  });

  test(
    'demo fetches work without account storage or an API transport',
    () async {
      expect(await MoodRepository().fetchMoodEntries(), hasLength(14));
      expect(await JournalRepository().fetchJournalEntries(), hasLength(5));
      expect(await NotificationRepository().fetchNotifications(), hasLength(6));
      expect(ContentRepository().catalog, hasLength(6));
      expect(demo.posts, hasLength(8));
    },
  );

  test(
    'demo editing, deletion, read state and bookmarks never need Hive or sync',
    () async {
      final moodRepo = MoodRepository();
      final now = DateTime.now();
      await moodRepo.saveMoodEntry(
        MoodEntry(
          id: 'review-edit',
          mood: 'calm',
          intensity: 5,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(moodRepo.currentEntries().first.id, 'review-edit');
      await moodRepo.deleteMoodEntry('review-edit');
      expect(moodRepo.currentEntries(), hasLength(14));
      final journalRepo = JournalRepository();
      final entry = journalRepo.currentEntries().first;
      await journalRepo.deleteJournalEntry(entry.id);
      expect(journalRepo.currentEntries(), hasLength(4));
      await journalRepo.saveJournalEntry(entry);
      expect(journalRepo.currentEntries(), hasLength(5));
      await NotificationRepository().markAllAsRead();
      expect(
        NotificationRepository().currentEntries().every((item) => item.read),
        isTrue,
      );
      final content = ContentRepository();
      await content.toggleSave({
        'id': 'demo-article-0',
        'title': 'A small pause',
      });
      expect(await content.isSaved('demo-article-0').first, isTrue);
      await content.toggleSave({'id': 'demo-article-0'});
      expect(await content.isSaved('demo-article-0').first, isFalse);
    },
  );

  test('changing modes switches streams and restores real data', () async {
    final mode = DemoMode();
    final real = StreamController<List<int>>();
    final iterator = StreamIterator(
      mode.selectStream(
        useDemo: () => mode.enabled,
        real: () => real.stream,
        demo: () => [9],
      ),
    );
    final first = iterator.moveNext();
    real.add([1, 2]);
    await first;
    expect(iterator.current, [1, 2]);
    mode.enabled = true;
    await iterator.moveNext();
    expect(iterator.current, [9]);
    mode.enabled = false;
    await iterator.moveNext();
    expect(iterator.current, [1, 2]);
    await iterator.cancel();
    await real.close();
    mode.dispose();
  });
}
