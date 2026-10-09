import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/sync_item.dart';
import 'package:cozy_health/core/models/sync_summary.dart';
import 'package:cozy_health/core/services/connection_sound.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:cozy_health/core/widgets/empty_state.dart';
import 'package:cozy_health/core/widgets/network_observer.dart';
import 'package:cozy_health/core/widgets/sync_queue_badge.dart';
import '../../support/repository_fixture.dart';
import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  setUpAll(() async {
    await installLocalTestFonts();
    await fixture.open();
    await local.settingsBox();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    networkOffline.value = null;
    await fixture.reset();
    await local.syncQueueBox.clear();
  });
  tearDownAll(() async {
    resetLocalTestFonts();
    await fixture.close();
  });

  Future<SyncItem> queue(String id) async {
    await local.enqueueSync(
      type: 'mood_entry',
      action: 'upsert',
      recordId: id,
      payload: {'id': id},
    );
    return local.pendingItems.singleWhere((item) => item.recordId == id);
  }

  test(
    'sync summary counts only acknowledged items and keeps failed changes',
    () async {
      final a = await queue('a');
      final b = await queue('b');
      fixture.body = {
        'data': {
          'results': [
            {'client_operation_id': a.id, 'success': true},
            {'client_operation_id': b.id, 'success': false},
          ],
        },
      };
      final result = await local.processSyncQueue();
      expect(result.synced, 1);
      expect(result.failed, 1);
      expect(local.pendingItems.single.recordId, 'b');
      expect(result.message, '1 synced, 1 failed — tap to retry');
    },
  );
  test(
    'malformed response cannot silently discard unacknowledged changes',
    () async {
      await queue('a');
      fixture.body = {'data': {}};
      final result = await local.processSyncQueue();
      expect(result.failed, 1);
      expect(local.pendingItems.length, 1);
    },
  );
  test('repeated failures never delete queued changes', () async {
    final item = await queue('a');
    fixture.body = {
      'data': {
        'results': [
          {'client_operation_id': item.id, 'success': false},
        ],
      },
    };
    for (var i = 0; i < 12; i++) {
      await local.processSyncQueue(force: true);
    }
    expect(local.pendingItems.single.retryCount, 12);
  });
  test(
    'manual retry bypasses backoff and successful acknowledgement drains queue',
    () async {
      final item = await queue('a');
      await local.syncQueueBox.put(
        item.id,
        item
            .copyWith(nextRetryAt: DateTime.now().add(const Duration(hours: 1)))
            .toJson(),
      );
      expect((await local.processSyncQueue()).attempted, 0);
      fixture.body = {
        'data': {
          'results': [
            {'client_operation_id': item.id, 'success': true},
          ],
        },
      };
      expect((await local.processSyncQueue(force: true)).synced, 1);
      expect(local.pendingItems, isEmpty);
    },
  );
  test(
    'sync messages distinguish success, partial failure and all failure',
    () {
      expect(const SyncSummary(synced: 3).message, '3 items synced');
      expect(
        const SyncSummary(failed: 2).message,
        "Couldn't sync. Tap to retry",
      );
    },
  );
  test(
    'missing optional sound asset does not require audio platform or crash',
    () async {
      await ConnectionSound().play();
    },
  );
  testWidgets('queued save uses local wording', (tester) async {
    await tester.runAsync(() => queue('a'));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppSnackbar.show(
                context,
                AppSnackbar.saved(type: 'mood_entry', id: 'a'),
              ),
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved locally — will sync when online'), findsOneWidget);
  });
  testWidgets('acknowledged save uses Saved', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppSnackbar.show(
                context,
                AppSnackbar.saved(type: 'mood_entry', id: 'a'),
              ),
              child: const Text('Save'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
  });
  testWidgets(
    'pending badge opens sheet without exposing notes or record IDs',
    (tester) async {
      await tester.runAsync(() => queue('private-record-id'));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SyncQueueBadge())),
      );
      expect(find.text('1 pending'), findsOneWidget);
      await tester.tap(find.text('1 pending'));
      await tester.pumpAndSettle();
      expect(find.text('Mood check-in'), findsOneWidget);
      expect(find.text('Retry sync'), findsOneWidget);
      expect(find.text('private-record-id'), findsNothing);
    },
  );
  testWidgets(
    'offline empty cache offers retry and returns to normal when online',
    (tester) async {
      var retries = 0;
      networkOffline.value = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Your moods will appear here.',
              onOfflineRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(find.text("You're offline."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 1);
      networkOffline.value = false;
      await tester.pump();
      expect(find.text('Your moods will appear here.'), findsOneWidget);
    },
  );

  Future<StreamController<List<ConnectivityResult>>> mountNetwork(
    WidgetTester tester, {
    required void Function() sound,
    required void Function() sync,
  }) async {
    final changes = StreamController<List<ConnectivityResult>>.broadcast();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: NetworkObserver(
            changes: changes.stream,
            check: () async => [ConnectivityResult.none],
            sync: () async {
              sync();
              return const SyncSummary();
            },
            playSound: () async => sound(),
            child: child!,
          ),
        ),
        home: const Scaffold(body: Text('Screen content')),
      ),
    );
    await tester.pump();
    addTearDown(changes.close);
    return changes;
  }

  testWidgets(
    'persistent banner appears on initial offline state, with reduced motion',
    (tester) async {
      await mountNetwork(tester, sound: () {}, sync: () {});
      expect(
        find.text("You're offline. Changes will sync when you reconnect."),
        findsOneWidget,
      );
      expect(find.text('Connection restored'), findsNothing);
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'restored transition debounces and triggers sound and sync once',
    (tester) async {
      var sounds = 0;
      var syncs = 0;
      final changes = await mountNetwork(
        tester,
        sound: () => sounds++,
        sync: () => syncs++,
      );
      changes.add([ConnectivityResult.wifi]);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(syncs, 0);
      changes.add([ConnectivityResult.wifi]);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Connection restored'), findsOneWidget);
      expect(sounds, 1);
      expect(syncs, 1);
    },
  );
  testWidgets('rapid flips cancel reconnect feedback', (tester) async {
    var sounds = 0;
    final changes = await mountNetwork(
      tester,
      sound: () => sounds++,
      sync: () {},
    );
    changes.add([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    changes.add([ConnectivityResult.none]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    expect(sounds, 0);
    expect(find.text('Connection restored'), findsNothing);
  });
  testWidgets('disposing observer cancels delayed feedback', (tester) async {
    var sounds = 0;
    final changes = await mountNetwork(
      tester,
      sound: () => sounds++,
      sync: () {},
    );
    changes.add([ConnectivityResult.wifi]);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(sounds, 0);
  });
}
