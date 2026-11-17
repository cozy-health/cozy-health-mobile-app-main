import 'dart:async';
import 'package:cozy_health/core/data/mood_recording_catalog.dart';
import 'package:cozy_health/features/mood_check_in/presentation/mood_recording_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/mood_recording_fakes.dart';

void main() {
  late MemoryMoodDrafts drafts;
  late MemoryMoodRepository repository;
  late MemoryMoodCatalog catalog;
  late MoodRecordingController flow;
  var scope = 'owner-a';
  late StreamController<void> accounts;
  setUp(() {
    drafts = MemoryMoodDrafts();
    repository = MemoryMoodRepository();
    catalog = MemoryMoodCatalog();
    accounts = StreamController<void>.broadcast(sync: true);
    scope = 'owner-a';
  });
  Future<void> open({bool historical = false}) async {
    flow = MoodRecordingController(
      entry: historical ? historicalMood() : null,
      repository: repository,
      drafts: drafts,
      wellness: catalog,
      accountScope: () => scope,
      accountChanges: accounts.stream,
    );
    addTearDown(flow.dispose);
    await flow.initialize();
  }

  tearDown(() async {
    await accounts.close();
  });
  void review() {
    while (flow.state.step != MoodRecordingStep.review) {
      flow.next();
    }
  }

  test('migrates all legacy positions, v2 positions and v3 idempotently', () {
    for (var step = 1; step <= 9; step++) {
      final expected = step <= 3
          ? 0
          : step <= 7
          ? 2
          : step == 8
          ? 3
          : 4;
      final migrated = migrateMoodRecordingDraft({
        'step': step,
        'intensity': 7,
        'note': 'Keep',
      });
      expect(migrated['step'], expected);
      expect(migrated['intensity'], 7);
      expect(migrateMoodRecordingDraft(migrated), migrated);
    }
    for (var step = 0; step < 4; step++) {
      expect(
        migrateMoodRecordingDraft({'version': 2, 'step': step})['step'],
        [0, 2, 3, 4][step],
      );
    }
    expect(migrateMoodRecordingDraft({'version': 3, 'step': 'bad'})['step'], 0);
    expect(
      () => migrateMoodRecordingDraft({'version': 99}),
      throwsFormatException,
    );
  });

  test(
    'five stages validate a specific feeling and preserve back navigation',
    () async {
      await open();
      expect(flow.canContinue, isFalse);
      flow.next();
      expect(flow.state.step, MoodRecordingStep.feeling);
      flow.selectFeeling('angry', 'angry-resentful');
      expect(flow.state.intensity, 6);
      flow.next();
      expect(flow.state.step, MoodRecordingStep.intensity);
      flow.setIntensity(5);
      flow.next();
      flow.toggleCause('Deadlines');
      flow.next();
      flow.setCoping({'Resting'});
      flow.back();
      expect(flow.state.step, MoodRecordingStep.causes);
      expect(flow.state.coping, {'Resting'});
      flow.next();
      flow.next();
      expect(flow.state.step, MoodRecordingStep.review);
      expect(flow.state.causes, {'Deadlines'});
      await Future<void>.delayed(Duration.zero);
      expect(drafts.data?['version'], 3);
      expect(drafts.data?['step'], 4);
    },
  );

  test(
    'Review cancellation restores fields and does not persist pending edits',
    () async {
      await open(historical: true);
      review();
      flow.edit(MoodRecordingStep.causes);
      flow.toggleCause('Deadlines');
      expect(flow.state.causes, contains('Deadlines'));
      flow.back();
      expect(flow.state.causes, {'Retired cause'});
      expect(flow.state.step, MoodRecordingStep.review);
      flow.edit(MoodRecordingStep.intensity);
      flow.setIntensity(1);
      flow.back();
      expect(flow.state.intensity, 7);
      expect(drafts.writes, isEmpty);
      flow.edit(MoodRecordingStep.causes);
      flow.toggleCause('Workload');
      flow.next();
      expect(flow.state.step, MoodRecordingStep.review);
      expect(flow.state.causes, {'Retired cause', 'Workload'});
    },
  );

  test(
    'changed feeling requires intensity confirmation and Back cancels both',
    () async {
      await open(historical: true);
      review();
      flow.edit(MoodRecordingStep.feeling);
      flow.selectFeeling('angry', 'angry-displaced');
      flow.next();
      expect(flow.state.step, MoodRecordingStep.intensity);
      expect(flow.state.intensity, 6);
      flow.back();
      expect(flow.state.expression, 'angry-resentful');
      expect(flow.state.intensity, 7);
      flow.edit(MoodRecordingStep.feeling);
      flow.selectFeeling('angry', 'angry-displaced');
      flow.next();
      flow.setIntensity(5);
      flow.next();
      expect(flow.state.step, MoodRecordingStep.review);
      expect(flow.state.expression, 'angry-displaced');
      expect(flow.state.intensity, 10);
    },
  );

  test(
    'visiting intensity preserves historical odd values and all hidden fields',
    () async {
      await open(historical: true);
      flow.next();
      flow.setIntensity(4);
      review();
      final saved = await flow.save();
      expect(saved?.intensity, 7);
      expect(saved?.bodySensations, ['Chest']);
      expect(saved?.sleepQuality, 2);
      expect(saved?.energyLevel, 4);
      expect(saved?.customTrigger, 'Keep this');
      expect(saved?.note, 'A long day');
      expect(saved?.copingHelped, 'somewhat');
      expect(saved?.createdAt, DateTime(2026));
      expect(saved?.copingStrategies, ['Old response']);
    },
  );

  test(
    'failure retries the same UUID and duplicate submissions are ignored',
    () async {
      await open();
      flow.selectFeeling('angry', 'angry-resentful');
      review();
      repository.fail = true;
      expect(await flow.save(), isNull);
      expect(flow.error, contains("couldn't save"));
      expect(drafts.data, isNotNull);
      repository.fail = false;
      final wait = Completer<void>();
      repository.waitForSave = wait.future;
      final saving = flow.save();
      await Future<void>.delayed(Duration.zero);
      expect(await flow.save(), isNull);
      wait.complete();
      final saved = await saving;
      expect(repository.attempts.map((e) => e.id).toSet(), hasLength(1));
      expect(repository.entries, hasLength(1));
      expect(saved, isNotNull);
      expect(drafts.data, isNull);
      expect(await flow.save(), isNull);
    },
  );

  test('cleanup failure does not invalidate a persisted entry', () async {
    await open();
    flow.selectFeeling('angry', 'angry-resentful');
    review();
    drafts.failClear = true;
    expect(await flow.save(), isNotNull);
    expect(flow.error, isNull);
  });

  test(
    'an account change during save prevents a receipt and draft cleanup',
    () async {
      await open();
      flow.selectFeeling('angry', 'angry-resentful');
      review();
      final pending = Completer<void>();
      repository.waitForSave = pending.future;
      final saving = flow.save();
      await Future<void>.delayed(Duration.zero);
      scope = 'owner-b';
      accounts.add(null);
      pending.complete();
      expect(await saving, isNull);
      expect(flow.active, isFalse);
      expect(drafts.data, isNotNull);
      expect(flow.saving, isFalse);
    },
  );

  test(
    'malformed resumed values require a new feeling without losing extras',
    () async {
      drafts.data = {
        'version': 3,
        'step': 4,
        'mood': ' ',
        'expression_slug': '',
        'intensity': 'invalid',
        'triggers': [7, 'Retired cause'],
        'note': 'Preserve this',
        'sleep': 'invalid',
      };
      await open();
      flow.resume();
      expect(flow.state.step, MoodRecordingStep.feeling);
      expect(flow.canContinue, isFalse);
      expect(flow.state.intensity, 6);
      flow.selectFeeling('angry', 'angry-resentful');
      review();
      final saved = await flow.save();
      expect(saved?.triggers, ['Retired cause']);
      expect(saved?.note, 'Preserve this');
      expect(saved?.sleepQuality, isNull);
    },
  );

  test(
    'resume preserves unknown values and rejects future draft versions',
    () async {
      drafts.data = {
        'version': 2,
        'step': 3,
        'id': '2c3ad192-df5d-4c44-bd32-c58369257709',
        'mood': 'angry',
        'expression_slug': 'angry-resentful',
        'intensity': 7,
        'coping': ['Retired response'],
        'triggers': ['Retired cause'],
        'note': 'Preserve',
      };
      await open();
      flow.resume();
      expect(flow.state.step, MoodRecordingStep.review);
      final saved = await flow.save();
      expect(saved?.copingStrategies, ['Retired response']);
      expect(saved?.note, 'Preserve');
      drafts.data = {'version': 99, 'step': 4};
      final future = MoodRecordingController(
        drafts: drafts,
        wellness: catalog,
        repository: repository,
        accountScope: () => scope,
        accountChanges: const Stream.empty(),
      );
      await future.initialize();
      expect(future.supportedDraft, isFalse);
      future.resume();
      expect(future.canContinue, isFalse);
      future.dispose();
    },
  );

  test(
    'late catalog results and persistence callbacks cannot cross accounts',
    () async {
      final remote = Completer<Map<String, dynamic>?>();
      catalog.pending = remote.future;
      flow = MoodRecordingController(
        drafts: drafts,
        repository: repository,
        wellness: catalog,
        accountScope: () => scope,
        accountChanges: accounts.stream,
      );
      addTearDown(flow.dispose);
      final initialize = flow.initialize();
      await Future<void>.delayed(Duration.zero);
      scope = 'owner-b';
      accounts.add(null);
      remote.complete({...moodRecordingCatalog, 'coping': <Object>[]});
      await initialize;
      expect(flow.active, isFalse);
      expect(flow.rows('coping'), hasLength(34));
      expect(await flow.save(), isNull);
      expect(repository.attempts, isEmpty);
    },
  );

  test(
    'custom server feeling names are used and catalog arrays are validated',
    () async {
      catalog.data = {
        ...moodRecordingCatalog,
        'expressions': [
          {'slug': 'custom-feeling', 'name': 'Custom feeling', 'feeling_id': 1},
        ],
      };
      await open();
      flow.selectFeeling('angry', 'custom-feeling');
      expect(flow.feeling, 'Custom feeling');
      expect(
        () => flow.state.causes.add('bad mutation'),
        throwsUnsupportedError,
      );
    },
  );
}
