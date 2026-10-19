import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/models/user_preferences.dart';
import 'package:cozy_health/core/models/sync_item.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/onboarding_service.dart';
import 'package:cozy_health/core/services/personalization_service.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cozy_health/features/onboarding/data/onboarding_data.dart';
import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  late Directory directory;
  final boundaryKey = GlobalKey();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await installLocalTestFonts();
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
    resetLocalTestFonts();
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(375, 812),
    double textScale = 1,
    bool reduceMotion = false,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
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
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 44, bottom: 34),
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: RepaintBoundary(key: boundaryKey, child: child!),
        ),
      ),
    );
    await tester.runAsync(() async {
      for (final page in OnboardingData.pages) {
        await precacheImage(
          AssetImage(page.asset),
          boundaryKey.currentContext!,
        );
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> toAccount(WidgetTester tester) async {
    await tap(tester, 'Skip');
    await tap(tester, 'Continue');
  }

  Future<void> finish(
    WidgetTester tester,
    String text, {
    bool fails = false,
  }) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text(text));
      for (var i = 0; i < 100; i++) {
        if (await OnboardingService().hasCompletedOnboarding()) break;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (fails && i > 10) break;
      }
    });
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('ONBOARDING_SCREENSHOTS')) return;
    await tester.runAsync(() async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = Directory('build/onboarding-review');
      await output.create(recursive: true);
      await File(
        '${output.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('Original three intros render in order with native controls', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Understand Your Emotions'), findsOneWidget);
    expect(await OnboardingService().hasCompletedOnboarding(), isFalse);
    await capture(tester, 'intro-emotions');
    await tap(tester, 'Next');
    expect(find.text('You\u2019re Not Alone'), findsOneWidget);
    await capture(tester, 'intro-community');
    await tap(tester, 'Next');
    expect(find.text('Your Safe Space'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);
    await capture(tester, 'intro-privacy');
    await tap(tester, 'Continue');
    expect(find.text('What brings you here?'), findsOneWidget);
    await capture(tester, 'preferences-focus');
    await tap(tester, 'Continue');
    expect(
      find.text('What are you struggling with right now?'),
      findsOneWidget,
    );
    await capture(tester, 'preferences-challenges');
    await finish(tester, 'Continue');
    expect(find.text('destination:${AppRouter.welcome}'), findsOneWidget);
    expect(find.text('How often do you want to check in?'), findsNothing);
    expect(find.text('How did you hear about us?'), findsNothing);
    expect(await OnboardingService().hasCompletedOnboarding(), isTrue);
  });

  testWidgets('Intro skip opens preferences; questions are optional', (
    tester,
  ) async {
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
  });

  testWidgets('Multiple selections, deselection and back preserve answers', (
    tester,
  ) async {
    await mount(tester);
    await tap(tester, 'Skip');
    await tap(tester, 'Anxiety');
    await tap(tester, 'Sleep');
    await tap(tester, 'Anxiety');
    await tap(tester, 'Continue');
    await tap(tester, 'Work');
    await tap(tester, 'Family');
    await tester.ensureVisible(find.byTooltip('Back'));
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final sleep = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sleep'),
    );
    expect(
      sleep.style!.backgroundColor!.resolve({}),
      AppTheme.light.colorScheme.primaryContainer,
    );
    await tap(tester, 'Continue');
    await finish(tester, 'Continue');
    final saved = await local.getUserPreferences();
    expect(saved!.focusAreas, ['Sleep']);
    expect(saved.currentChallenges, ['Work', 'Family']);
    expect(saved.skipped, isFalse);
    expect(saved.completedAt.isUtc, isTrue);
    expect(find.text('destination:${AppRouter.welcome}'), findsOneWidget);
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
    expect(queued.payload!['focus_areas'], ['Sleep']);
  });

  testWidgets('Skip clears the current question only', (tester) async {
    await mount(tester);
    await tap(tester, 'Skip');
    await tap(tester, 'Stress');
    await tap(tester, 'Skip');
    await tap(tester, 'Health');
    await finish(tester, 'Continue');
    final saved = await local.getUserPreferences();
    expect(saved!.focusAreas, isEmpty);
    expect(saved.currentChallenges, ['Health']);
    expect(saved.skipped, isTrue);
    expect(find.text('destination:${AppRouter.welcome}'), findsOneWidget);
  });

  testWidgets('Existing fields and tour completion survive onboarding save', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await local.saveUserPreferences(
        UserPreferences(
          focusAreas: [],
          currentChallenges: [],
          checkInFrequency: 'Daily',
          attribution: 'Friend',
          completedAt: DateTime.utc(2026),
          skipped: false,
        ),
      );
      await (await local.settingsBox()).put('has_seen_tour', true);
    });
    await mount(tester);
    await toAccount(tester);
    await finish(tester, 'Skip');
    final saved = await local.getUserPreferences();
    expect(saved!.checkInFrequency, 'Daily');
    expect(saved.attribution, 'Friend');
    expect((await local.settingsBox()).get('has_seen_tour'), isTrue);
    expect(local.syncQueueBox.length, 1);
  });

  testWidgets('Failed save stays on preferences and can be retried', (
    tester,
  ) async {
    await mount(tester);
    await toAccount(tester);
    late Box<int> wrongBox;
    await tester.runAsync(() async {
      await local.syncQueueBox.close();
      wrongBox = await EncryptedHive.openBox<int>(
        LocalDbService.syncQueueBoxName,
      );
    });
    await finish(tester, 'Continue', fails: true);
    expect(
      find.text("We couldn't save your choices. Please try again."),
      findsOneWidget,
    );
    expect(await OnboardingService().hasCompletedOnboarding(), isFalse);
    expect(find.text('Continue'), findsOneWidget);
    await tester.runAsync(() async {
      await wrongBox.close();
      await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
    });
    await finish(tester, 'Continue');
    expect(find.text('destination:${AppRouter.welcome}'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(375, 812),
    const Size(667, 375),
  ]) {
    testWidgets(
      'All screens remain usable at $size with enlarged text and reduced motion',
      (tester) async {
        await mount(tester, size: size, textScale: 2, reduceMotion: true);
        await tap(tester, 'Next');
        await tap(tester, 'Next');
        await tap(tester, 'Continue');
        await tap(tester, 'Continue');
        expect(find.text('Continue'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Introduction swipes horizontally and inherits dark appearance', (
    tester,
  ) async {
    await mount(tester, brightness: Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).brightness,
      Brightness.dark,
    );
    await tester.drag(find.byType(PageView), const Offset(-350, 0));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingData.pages[1].title), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(350, 0));
    await tester.pumpAndSettle();
    expect(find.text(OnboardingData.pages[0].title), findsOneWidget);
    expect(find.text('I already have an account'), findsNothing);
    await capture(tester, 'intro-dark');
  });

  test('Preference adapter persists after reopening', () async {
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
}
