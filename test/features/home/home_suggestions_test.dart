import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/models/user_preferences.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/services/home_suggestions.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/security_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/security_gate.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/widgets/preference_suggestions.dart';
import 'package:cozy_health/features/journal/presentation/screens/journal_screen.dart';
import '../../support/local_fonts.dart';

UserPreferences preferences({
  List<String> focus = const [],
  List<String> challenges = const [],
}) => UserPreferences(
  focusAreas: focus,
  currentChallenges: challenges,
  checkInFrequency: 'A few times a week',
  completedAt: DateTime.utc(2026),
  skipped: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  final local = LocalDbService();
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await installLocalTestFonts();
    directory = await Directory.systemTemp.createTemp('cozy_suggestions_');
    Hive.init(directory.path);
    await local.preferencesBox();
    Hive.registerAdapter(JournalEntryAdapter());
    await EncryptedHive.openBox<JournalEntry>(LocalDbService.journalBoxName);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SecurityService.instance.lockJournal();
    await SecurityService.instance.removePin();
    await (await local.preferencesBox()).clear();
    await local.journalBox.clear();
  });
  tearDownAll(() async {
    resetLocalTestFonts();
    await Hive.close();
    Hive.resetAdapters();
    await directory.delete(recursive: true);
  });

  test('Missing and empty answers keep generic Home', () {
    expect(homeSuggestions(null), isEmpty);
    expect(homeSuggestions(preferences()), isEmpty);
    expect(homeSuggestions(preferences(focus: ['future option'])), isEmpty);
  });

  test('Stress and anxiety give one breathing suggestion', () {
    final suggestions = homeSuggestions(
      preferences(focus: ['Stress', 'Anxiety']),
    );
    expect(suggestions, hasLength(1));
    expect(suggestions.single.isBreathing, isTrue);
    expect(suggestions.single.reason, contains('anxiety'));
  });

  for (final focus in ['Low mood', 'Sleep', 'Relationships', 'Self-growth']) {
    test('$focus supplies a journal prompt', () {
      final suggestion = homeSuggestions(preferences(focus: [focus])).single;
      expect(suggestion.isBreathing, isFalse);
      expect(suggestion.prompt, isNotEmpty);
      expect(suggestion.reason, contains(focus.toLowerCase()));
    });
  }

  for (final challenge in [
    'Work',
    'School',
    'Family',
    'Health',
    'Money',
    'Loneliness',
  ]) {
    test('$challenge tailors journaling independently of focus', () {
      final suggestion = homeSuggestions(
        preferences(challenges: [challenge]),
      ).single;
      expect(suggestion.isBreathing, isFalse);
      expect(suggestion.id, contains(challenge.toLowerCase()));
      expect(suggestion.prompt, isNotEmpty);
    });
  }

  test('Multiple choices yield at most two cards and use display order', () {
    final suggestions = homeSuggestions(
      preferences(
        focus: ['Self-growth', 'Stress', 'Anxiety'],
        challenges: ['Family', 'Work'],
      ),
    );
    expect(suggestions, hasLength(2));
    expect(suggestions.first.isBreathing, isTrue);
    expect(
      suggestions.last.prompt,
      'What has felt difficult about work lately?',
    );
  });

  Future<GoRouter> mount(
    WidgetTester tester, {
    bool realJournal = false,
  }) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final composeRoute = AppRouter.router.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((route) => route.path == '/journal-compose');
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(child: PreferenceSuggestions()),
          ),
        ),
        GoRoute(
          path: AppRouter.breathing,
          builder: (_, _) =>
              const Scaffold(body: Text('breathing destination')),
        ),
        if (realJournal)
          composeRoute
        else
          GoRoute(
            path: '/journal-compose',
            builder: (_, state) {
              final prompt = state.extra! as JournalPrompt;
              return Scaffold(body: Text('${prompt.id}: ${prompt.text}'));
            },
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('Suggestions react to restored preferences and open breathing', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('A starting point for you'), findsNothing);
    await tester.runAsync(() async {
      await (await local.preferencesBox()).put(
        'current',
        preferences(focus: ['Stress']),
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('Based on your focus on stress'), findsOneWidget);
    await tester.tap(find.text('Try breathing'));
    await tester.pumpAndSettle();
    expect(find.text('breathing destination'), findsOneWidget);
  });

  testWidgets('Journal action carries the selected prompt', (tester) async {
    await tester.runAsync(() async {
      await (await local.preferencesBox()).put(
        'current',
        preferences(challenges: ['Work']),
      );
    });
    await mount(tester);
    await tester.tap(find.text('Write about this'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'onboarding_challenge_work: What has felt difficult about work lately?',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Real compose route retains prompt through PIN gate and leaves writing empty',
    (tester) async {
      await tester.runAsync(() async {
        await (await local.preferencesBox()).put(
          'current',
          preferences(challenges: ['Work']),
        );
        await SecurityService.instance.setPin('1234');
      });
      await mount(tester, realJournal: true);
      await tester.tap(find.text('Write about this'));
      await tester.pumpAndSettle();
      expect(find.byType(SecurityGate), findsOneWidget);
      expect(find.byType(JournalEditorScreen), findsNothing);
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Open journal'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(find.byType(JournalEditorScreen), findsOneWidget);
      expect(
        find.text('"What has felt difficult about work lately?"'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(local.journalBox.values, isEmpty);
    },
  );
}
