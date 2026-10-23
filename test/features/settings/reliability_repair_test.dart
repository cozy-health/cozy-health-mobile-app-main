import 'package:cozy_health/features/journal/presentation/screens/journal_screen.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/features/settings/presentation/screens/notification_preferences_screen.dart';
import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/settings/presentation/screens/profile_view_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/subscription_screen.dart';
import 'package:cozy_health/features/insights/presentation/screens/monthly_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/repository_fixture.dart';
import '../../support/mobile_sync_contract.dart';
import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<MoodEntry>(
    LocalDbService.moodBoxName,
    MoodEntryAdapter(),
  );
  final local = LocalDbService();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await fixture.open();
    registerSyncAdapters();
    await installLocalTestFonts();
  });
  setUp(() async {
    await local.waitForSyncIdle();
    await local.activateAccount('42');
    await local.clearAllUserData();
    await TokenStorage().saveToken('synthetic-session');
    fixture.body = {'data': []};
  });
  tearDownAll(fixture.close);

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: RepaintBoundary(key: surfaceCaptureKey, child: screen),
        ),
      );
      for (var attempt = 0; attempt < 20; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
        if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'journal editor clears unfinished text before a different account can use it',
    (tester) async {
      await show(tester, const JournalEditorScreen(type: 'Free'));
      await tester.enterText(
        find.byType(TextField),
        'Private unfinished journal',
      );
      await tester.runAsync(() async {
        await local.activateAccount('different-account');
        await TokenStorage().saveToken('different-session');
      });
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Private unfinished journal'), findsNothing);
      expect(local.getJournalDraft('journal_draft_Free_free'), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'offline community settings preserve separate inbox and phone choices',
    (tester) async {
      final wasPaused = local.syncPaused;
      local.syncPaused = true;
      addTearDown(() => local.syncPaused = wasPaused);
      await tester.runAsync(() async {
        await local.saveUserProfile(
          UserProfile(
            id: 'settings-profile',
            name: 'Test account',
            email: 'test@example.com',
            pushConsent: false,
            notificationsMaster: true,
            updatedAt: DateTime.now(),
          ),
        );
      });
      await show(tester, const NotificationPreferencesScreen());
      final likes = find.widgetWithText(SwitchListTile, 'Likes on my posts');
      await tester.scrollUntilVisible(likes, 250);
      expect(tester.widget<SwitchListTile>(likes).value, isTrue);
      expect(tester.widget<SwitchListTile>(likes).onChanged, isNotNull);
      final phone = find.widgetWithText(
        SwitchListTile,
        'Community phone alerts',
      );
      await tester.ensureVisible(phone);
      expect(tester.widget<SwitchListTile>(phone).onChanged, isNull);
      await tester.ensureVisible(likes);
      await tester.runAsync(() async {
        await tester.tap(likes);
        for (
          var attempt = 0;
          attempt < 50 && local.pendingItems.isEmpty;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(
          local.pendingItems.any((item) => item.type == 'user_profile'),
          isTrue,
        );
        await local.waitForSyncIdle();
      });
      await tester.pumpAndSettle();
      expect(
        local.getUserProfile()!.reminderSettings['community_likes_enabled'],
        isFalse,
      );
      expect(local.getUserProfile()!.pushConsent, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'monthly navigation changes the month and prevents future months',
    (tester) async {
      await show(tester, const MonthlyReportScreen());
      final now = DateTime.now();
      expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);
      final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
      expect(tester.widget<IconButton>(next).onPressed, isNull);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(
        find.text(
          DateFormat('MMMM yyyy').format(DateTime(now.year, now.month - 1)),
        ),
        findsOneWidget,
      );
      expect(tester.widget<IconButton>(next).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      await captureSurface(tester, 'reliability-monthly-report');
    },
  );

  testWidgets('regional pricing shows actual monthly and annual totals', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (await local.settingsBox()).put('billing_country', 'NG');
    });
    fixture.body = {
      'data': {
        'packages': [
          {
            'tier': 'student',
            'package_name': 'Student',
            'price': '5000',
            'yearly_price': 48000,
            'currency': 'NGN',
            'currency_decimals': 0,
            'annual_discount': 20,
            'features': ['Journaling'],
          },
          {
            'tier': 'premium',
            'package_name': 'Premium',
            'price': '10000',
            'yearly_price': 96000,
            'currency': 'NGN',
            'currency_decimals': 0,
            'annual_discount': 20,
            'features': ['Journaling'],
          },
        ],
      },
    };
    await show(tester, const SubscriptionScreen(deferBilling: true));
    expect(find.text('NGN 5,000/month'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('NGN 48,000/year'), findsOneWidget);
    expect(find.text('NGN 96,000/year'), findsOneWidget);
    expect(find.text('Start Free Trial'), findsNothing);
    expect(find.byKey(const ValueKey('restore-store-purchases')), findsNothing);
    await tester.ensureVisible(find.text('Student'));
    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();
    expect(find.text('Billing unavailable'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('wellness-sheet-close')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await captureSurface(tester, 'reliability-regional-prices');
  });

  testWidgets('all earned milestones remain visible after a streak ends', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (var day = 1; day <= 3; day++) {
        await local.saveMoodEntry(
          MoodEntry(
            id: 'mood-$day',
            mood: 'good',
            intensity: 5,
            createdAt: DateTime.utc(2026, 10, day),
            updatedAt: DateTime.utc(2026, 10, day),
          ),
        );
      }
    });
    await show(tester, const AchievementsScreen());
    expect(find.textContaining('2 of 5 milestones earned.'), findsOneWidget);
    expect(
      tester
          .widget<AchievementContent>(find.byType(AchievementContent))
          .snapshot
          .awards
          .keys,
      containsAll(['first_mood', 'streak_3']),
    );
    expect(find.text('Your first check-in'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Three steady days'), 300);
    expect(find.text('Three steady days'), findsOneWidget);
    await captureSurface(tester, 'reliability-achievements');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => local.moodBox.clear());
    await show(tester, const AchievementsScreen());
    expect(find.textContaining('2 of 5 milestones earned.'), findsOneWidget);
    final snapshot = tester
        .widget<AchievementContent>(find.byType(AchievementContent))
        .snapshot;
    expect(snapshot.progress.current, 0);
    expect(snapshot.awards.keys, containsAll(['first_mood', 'streak_3']));
    expect(tester.takeException(), isNull);
  });
}
