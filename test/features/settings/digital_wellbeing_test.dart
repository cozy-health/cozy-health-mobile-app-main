import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/models/digital_wellbeing_preferences.dart';
import 'package:cozy_health/core/services/digital_wellbeing_service.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/digital_wellbeing_screen.dart';

class _MemoryService extends DigitalWellbeingService {
  DigitalWellbeingPreferences value = const DigitalWellbeingPreferences();
  Completer<void>? gate;
  bool failLoad = false;
  @override
  Future<DigitalWellbeingPreferences> load() async {
    if (failLoad) throw StateError('Unavailable');
    return value;
  }

  @override
  Future<void> save(DigitalWellbeingPreferences preferences) async {
    if (gate != null) await gate!.future;
    value = preferences;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('cozy_wellbeing_');
    Hive.init(directory.path);
  });
  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('wellbeing defaults are off with no suggested limit', () {
    const value = DigitalWellbeingPreferences();
    expect(value.gentleReminders, isFalse);
    expect(value.showUsageSummary, isFalse);
    expect(value.dailyLimitMinutes, 0);
  });
  test('unrecognized stored limits fall back to no limit', () {
    expect(
      DigitalWellbeingPreferences.fromMap({
        'daily_limit_minutes': 99,
      }).dailyLimitMinutes,
      0,
    );
  });
  test(
    'all preferences survive reopening Hive with a durable future-sync intent',
    () async {
      final service = DigitalWellbeingService();
      await service.save(
        const DigitalWellbeingPreferences(
          gentleReminders: true,
          dailyLimitMinutes: 30,
          showUsageSummary: true,
        ),
      );
      await (await LocalDbService().settingsBox()).close();
      final value = await service.load();
      expect(value.gentleReminders, isTrue);
      expect(value.dailyLimitMinutes, 30);
      expect(value.showUsageSummary, isTrue);
      expect(
        (await LocalDbService().settingsBox()).get(
          DigitalWellbeingService.pendingSyncKey,
        ),
        isTrue,
      );
      expect(Hive.isBoxOpen(LocalDbService.syncQueueBoxName), isFalse);
    },
  );
  testWidgets(
    'settings render defaults without enforcing reminders or limits',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DigitalWellbeingScreen(service: _MemoryService())),
      );
      await tester.pumpAndSettle();
      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches.every((tile) => !tile.value), isTrue);
      expect(find.text('No limit'), findsOneWidget);
    },
  );
  testWidgets('both toggles and dropdown save the selected preferences', (
    tester,
  ) async {
    final service = _MemoryService();
    await tester.pumpWidget(
      MaterialApp(home: DigitalWellbeingScreen(service: service)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gentle reminders'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show usage summary at close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 min').last);
    await tester.pumpAndSettle();
    expect(service.value.gentleReminders, isTrue);
    expect(service.value.showUsageSummary, isTrue);
    expect(service.value.dailyLimitMinutes, 30);
  });
  testWidgets('controls disable while a preference is saving', (tester) async {
    final service = _MemoryService()..gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: DigitalWellbeingScreen(service: service)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gentle reminders'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .every((tile) => tile.onChanged == null),
      isTrue,
    );
    service.gate!.complete();
    await tester.pumpAndSettle();
    expect(service.value.gentleReminders, isTrue);
  });
  testWidgets('failed settings load offers working retry', (tester) async {
    final service = _MemoryService()..failLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: DigitalWellbeingScreen(service: service)),
    );
    await tester.pumpAndSettle();
    expect(find.text("We couldn't load your data."), findsOneWidget);
    service.failLoad = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Gentle reminders'), findsOneWidget);
  });
}
