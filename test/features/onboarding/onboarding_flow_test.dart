import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/models/user_preferences.dart';
import 'package:cozy_health/core/models/sync_item.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/onboarding_service.dart';
import 'package:cozy_health/core/services/personalization_service.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/widgets/app_button.dart';
import 'package:cozy_health/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cozy_health/features/onboarding/presentation/screens/steps/preview_step.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  late Directory directory;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    directory = await Directory.systemTemp.createTemp('cozy_onboarding_test_');
    Hive.init(directory.path);
    await local.preferencesBox();
    await local.settingsBox();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await (await local.preferencesBox()).clear();
    await (await local.settingsBox()).clear();
    await local.syncQueueBox.clear();
  });
  tearDownAll(() async {
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  Future<void> mount(WidgetTester tester, {bool reduceMotion = false}) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: AppRouter.onboarding,
      routes: [
        GoRoute(
          path: AppRouter.onboarding,
          builder: (_, _) => const OnboardingScreen(),
        ),
        for (final route in [
          AppRouter.createAccount,
          AppRouter.welcome,
          AppRouter.login,
        ])
          GoRoute(
            path: route,
            builder: (_, _) => Scaffold(body: Text('destination:$route')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> toAccount(WidgetTester tester) async {
    for (var step = 0; step < 6; step++) {
      await tap(tester, step == 3 ? 'Continue' : 'Skip');
    }
  }

  Future<void> finish(WidgetTester tester, String text) async {
    await tester.runAsync(() async {
      await tester.tap(find.text(text));
      for (
        var i = 0;
        i < 100 && !await OnboardingService().hasCompletedOnboarding();
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('Each step renders and progress updates across seven steps', (
    tester,
  ) async {
    await mount(tester);
    final titles = [
      "Let's get to know you.",
      'What brings you here?',
      'What are you struggling with right now?',
      'How often do you want to check in?',
      'How did you hear about us?',
      "Here's what we'll focus on.",
      'Make this space yours.',
    ];
    for (var i = 0; i < 7; i++) {
      expect(find.text(titles[i]), findsOneWidget);
      expect(find.text('Step ${i + 1} of 7'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        closeTo((i + 1) / 7, .001),
      );
      if (i < 6) await tap(tester, i == 3 ? 'Continue' : 'Skip');
    }
  });

  testWidgets(
    'Focus requires one selection, supports multiple and deselection',
    (tester) async {
      await mount(tester);
      await tap(tester, 'Continue');
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      await tap(tester, 'Anxiety');
      await tap(tester, 'Sleep');
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNotNull,
      );
      await tap(tester, 'Anxiety');
      await tap(tester, 'Sleep');
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'Challenges require a selection and cannot be bypassed by swiping',
    (tester) async {
      await mount(tester);
      await tap(tester, 'Skip');
      await tap(tester, 'Skip');
      expect(find.text('Step 3 of 7'), findsOneWidget);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).onPressed,
        isNull,
      );
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 7'), findsOneWidget);
      await tap(tester, 'Work');
      await tap(tester, 'Continue');
      expect(find.text('Step 4 of 7'), findsOneWidget);
    },
  );

  testWidgets('Frequency defaults and intentionally has no Skip control', (
    tester,
  ) async {
    await mount(tester);
    for (var i = 0; i < 3; i++) {
      await tap(tester, 'Skip');
    }
    expect(find.text('Skip'), findsNothing);
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'A few times a week',
    );
    await tap(tester, 'Daily');
    expect(
      tester
          .widget<RadioGroup<String>>(find.byType(RadioGroup<String>))
          .groupValue,
      'Daily',
    );
  });

  testWidgets('Preview reflects chosen focus, challenges and frequency', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, 'Continue');
    await tap(tester, 'Anxiety');
    await tap(tester, 'Sleep');
    await tap(tester, 'Continue');
    await tap(tester, 'Work');
    await tap(tester, 'Family');
    await tap(tester, 'Continue');
    await tap(tester, 'Daily');
    await tap(tester, 'Continue');
    await tap(tester, 'Friend');
    await tap(tester, 'Continue');
    final preview = tester.widget<PreviewStep>(find.byType(PreviewStep));
    expect(preview.focusAreas, {'Anxiety', 'Sleep'});
    expect(preview.challenges, {'Work', 'Family'});
    expect(preview.frequency, 'Daily');
    expect(find.text('Looks good'), findsOneWidget);
    await tap(tester, 'Edit preferences');
    expect(find.text('Step 2 of 7'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Back preserves previous selections', (tester) async {
    await mount(tester);
    await tap(tester, 'Continue');
    await tap(tester, 'Stress');
    await tap(tester, 'Continue');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 7'), findsOneWidget);
    expect(
      tester.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('Skipping selected focus clears it before preview', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, 'Continue');
    await tap(tester, 'Anxiety');
    await tap(tester, 'Skip');
    await tap(tester, 'Skip');
    await tap(tester, 'Continue');
    await tap(tester, 'Skip');
    expect(
      tester.widget<PreviewStep>(find.byType(PreviewStep)).focusAreas,
      isEmpty,
    );
  });

  testWidgets(
    'Finish saves Hive preferences, settings mirror and sync intent',
    (tester) async {
      await mount(tester);
      await tap(tester, 'Continue');
      await tap(tester, 'Self-growth');
      await tap(tester, 'Continue');
      await tap(tester, 'Health');
      await tap(tester, 'Continue');
      await tap(tester, 'When I need it');
      await tap(tester, 'Continue');
      await tap(tester, 'Search');
      await tap(tester, 'Continue');
      await tap(tester, 'Looks good');
      await finish(tester, 'Create account');
      expect(
        find.text('destination:${AppRouter.createAccount}'),
        findsOneWidget,
      );
      final saved = await local.getUserPreferences();
      expect(saved!.focusAreas, ['Self-growth']);
      expect(saved.currentChallenges, ['Health']);
      expect(saved.checkInFrequency, 'When I need it');
      expect(saved.attribution, 'Search');
      expect(saved.skipped, isFalse);
      expect(saved.completedAt.isUtc, isTrue);
      expect(
        (await local.settingsBox()).get('onboarding_preferences'),
        saved.toJson(),
      );
      expect((await local.settingsBox()).get('has_seen_tour'), isFalse);
      expect(
        await PersonalizationService().hasCompletedPersonalization(),
        isTrue,
      );
      final queued = SyncItem.fromJson(local.syncQueueBox.values.single);
      expect(queued.type, 'user_preferences');
      expect(queued.action, 'upsert');
      expect(queued.payload!['focus_areas'], ['Self-growth']);
    },
  );

  testWidgets(
    'Skipping account saves defaults and preserves guest/login route',
    (tester) async {
      await mount(tester);
      await toAccount(tester);
      await finish(tester, 'Skip');
      expect(find.text('destination:${AppRouter.welcome}'), findsOneWidget);
      final saved = await local.getUserPreferences();
      expect(saved!.focusAreas, isEmpty);
      expect(saved.currentChallenges, isEmpty);
      expect(saved.checkInFrequency, 'A few times a week');
      expect(saved.attribution, isNull);
      expect(saved.skipped, isTrue);
    },
  );

  testWidgets('Existing account action saves preferences then opens login', (
    tester,
  ) async {
    await mount(tester);
    await toAccount(tester);
    await finish(tester, 'I already have an account');
    expect(find.text('destination:${AppRouter.login}'), findsOneWidget);
    expect(await local.getUserPreferences(), isNotNull);
  });

  testWidgets('Reduced motion changes steps without entrance animation', (
    tester,
  ) async {
    await mount(tester, reduceMotion: true);
    await tap(tester, 'Continue');
    expect(find.text('Step 2 of 7'), findsOneWidget);
    final fade = tester.widget<FadeTransition>(
      find.byType(FadeTransition).first,
    );
    expect(fade.opacity.value, 1);
  });

  test('Preference adapter persists after reopening the Hive box', () async {
    final preferences = UserPreferences(
      focusAreas: ['Sleep'],
      currentChallenges: ['Work'],
      checkInFrequency: 'Daily',
      completedAt: DateTime.utc(2026, 10, 8),
      skipped: false,
    );
    await local.saveUserPreferences(preferences);
    await (await local.preferencesBox()).close();
    expect((await local.getUserPreferences())!.toJson(), preferences.toJson());
  });

  test('Saving preferences twice keeps one durable sync intent', () async {
    final preferences = UserPreferences(
      focusAreas: [],
      currentChallenges: [],
      checkInFrequency: 'Daily',
      completedAt: DateTime.now().toUtc(),
      skipped: true,
    );
    await local.saveUserPreferences(preferences);
    await local.saveUserPreferences(preferences);
    expect(local.syncQueueBox.length, 1);
    final item = SyncItem.fromJson(local.syncQueueBox.values.single);
    expect(item.retryCount, 0);
    expect(item.nextRetryAt, isNull);
  });
}
