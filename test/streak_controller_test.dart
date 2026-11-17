import 'dart:async';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/streak_progress.dart';
import 'package:cozy_health/core/models/sync_summary.dart';
import 'package:cozy_health/core/repositories/streak_repository.dart';
import 'package:cozy_health/core/services/streak_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'streak_progress_test.dart' show baseline, mood;

class _Repository extends StreakRepository {
  StreakProgress? saved;
  bool fail = false;
  Completer<StreakProgress>? delayed;
  StreakProgress fresh = baseline();
  @override
  Future<StreakProgress?> cached() async => saved;
  @override
  Future<StreakProgress> fetch() async {
    if (delayed != null) return delayed!.future;
    if (fail) throw StateError('offline');
    saved = fresh;
    return fresh;
  }
}

void main() {
  test(
    'session clearing immediately hides progress without deleting saved work',
    () async {
      final clearing = StreamController<void>.broadcast(sync: true);
      final repository = _Repository()..saved = baseline();
      final controller = StreakController(
        repository: repository,
        now: () => DateTime.utc(2026, 10, 7, 12),
        localMoods: () => [],
        moodChanges: const Stream.empty(),
        accountChanges: const Stream.empty(),
        syncResults: const Stream.empty(),
        sessionClearing: clearing.stream,
        sessionChanges: const Stream.empty(),
        tick: false,
      );
      controller.start();
      await pumpEventQueue();
      expect(controller.progress?.currentDays, 7);
      clearing.add(null);
      expect(controller.progress, isNull);
      expect(repository.saved?.currentDays, 7);
      controller.dispose();
      await clearing.close();
    },
  );
  testWidgets(
    'account-local midnight spends a rest day without incrementing the number',
    (tester) async {
      var now = DateTime.utc(2026, 10, 8, 23, 59, 59);
      final controller = StreakController(
        repository: _Repository(),
        now: () => now,
        localMoods: () => [],
        moodChanges: const Stream.empty(),
        accountChanges: const Stream.empty(),
        syncResults: const Stream.empty(),
      );
      controller.start();
      await tester.pump();
      expect(controller.progress?.restDays, 1);
      now = DateTime.utc(2026, 10, 9, 0, 0, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.progress?.currentDays, 7);
      expect(controller.progress?.restDays, 0);
      expect(controller.progress?.protectedDates, {'2026-10-08'});
      controller.dispose();
    },
  );
  test(
    'offline reopening retains bank/protection and late saves reconcile after sync',
    () async {
      final repository = _Repository()
        ..saved = baseline()
        ..fail = true;
      final changes = StreamController<List<MoodEntry>>.broadcast(sync: true);
      final sync = StreamController<SyncSummary>.broadcast(sync: true);
      var moods = <MoodEntry>[];
      final controller = StreakController(
        repository: repository,
        now: () => DateTime.utc(2026, 10, 9, 12),
        localMoods: () => moods,
        moodChanges: changes.stream,
        syncResults: sync.stream,
        accountChanges: const Stream.empty(),
        tick: false,
      );
      addTearDown(() async {
        controller.dispose();
        await changes.close();
        await sync.close();
      });
      controller.start();
      await pumpEventQueue();
      expect(controller.offline, isTrue);
      expect(controller.progress?.currentDays, 7);
      expect(controller.progress?.restDays, 0);
      expect(controller.progress?.protectedDates, {'2026-10-08'});
      moods = [
        mood('late', '2026-10-08T12:00:00Z'),
        mood('today', '2026-10-09T12:00:00Z'),
      ];
      changes.add(moods);
      expect(controller.progress?.currentDays, 9);
      expect(controller.progress?.restDays, 1);
      expect(controller.progress?.estimated, isTrue);
      final json = baseline(count: 9).toJson()
        ..['as_of'] = '2026-10-09T12:00:00Z';
      (json['credited_sources'] as Map<String, String>).addAll({
        'late': '2026-10-08',
        'today': '2026-10-09',
      });
      repository.fresh = StreakProgress.fromJson(json);
      repository.fail = false;
      sync.add(const SyncSummary(synced: 2));
      await pumpEventQueue();
      expect(controller.offline, isFalse);
      expect(controller.progress?.currentDays, 9);
      expect(controller.progress?.pendingDates, isEmpty);
      expect(controller.progress?.estimated, isFalse);
    },
  );

  test(
    'account change clears visible progress and ignores a delayed old request',
    () async {
      final repository = _Repository()..saved = baseline();
      final account = StreamController<void>.broadcast(sync: true);
      final controller = StreakController(
        repository: repository,
        now: () => DateTime.utc(2026, 10, 7, 12),
        localMoods: () => [],
        moodChanges: const Stream.empty(),
        syncResults: const Stream.empty(),
        accountChanges: account.stream,
        tick: false,
      );
      addTearDown(() async {
        controller.dispose();
        await account.close();
      });
      controller.start();
      await pumpEventQueue();
      expect(controller.progress?.currentDays, 7);
      final held = Completer<StreakProgress>();
      repository.delayed = held;
      final oldRequest = controller.refresh();
      await pumpEventQueue();
      repository.saved = null;
      repository.delayed = null;
      repository.fail = true;
      account.add(null);
      expect(controller.progress, isNull);
      await pumpEventQueue();
      held.complete(baseline());
      await oldRequest;
      expect(controller.progress, isNull);
      expect(controller.offline, isTrue);
    },
  );
}
