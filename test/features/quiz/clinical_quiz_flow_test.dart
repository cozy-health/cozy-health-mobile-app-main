import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/quiz/domain/clinical_assessment.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_taking_screen.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_selection_screen.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/clinical_disclaimer_sheet.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_support_sheet.dart';
import '../../support/local_fonts.dart';
import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<QuizAttempt>(
    LocalDbService.quizAttemptBoxName,
    QuizAttemptAdapter(),
  );
  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    await installLocalTestFonts();
    final settings = await LocalDbService.instance.settingsBox();
    await settings.put(ClinicalDisclaimerSheet.acknowledgementKey, true);
  });
  tearDown(resetLocalTestFonts);
  tearDownAll(fixture.close);
  for (final assessment in ClinicalAssessment.all) {
    testWidgets(
      '${assessment.id} submits every answer with real ID and score',
      (tester) async {
        Map<String, dynamic>? submitted;
        final router = GoRouter(
          initialLocation: '/taking',
          routes: [
            GoRoute(
              path: '/taking',
              builder: (_, _) => QuizTakingScreen(
                extra: {'id': assessment.id, 'type': 'clinical'},
              ),
            ),
            GoRoute(
              path: AppRouter.quizResults,
              builder: (_, state) {
                submitted = Map<String, dynamic>.from(state.extra as Map);
                return const Scaffold(body: Text('Submitted'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(routerConfig: router, theme: AppTheme.light),
        );
        await tester.pumpAndSettle();
        for (
          var question = 0;
          question < assessment.questions.length;
          question++
        ) {
          expect(
            find.text(
              'Question ${question + 1} of ${assessment.questions.length}',
            ),
            findsOneWidget,
          );
          await tester.ensureVisible(find.text('Several days'));
          await tester.tap(find.text('Several days'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(
              question == assessment.questions.length - 1 ? 'Submit' : 'Next',
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(submitted!['id'], assessment.id);
        expect(submitted!['score'], assessment.questions.length);
        expect(
          submitted!['answers'],
          List.filled(assessment.questions.length, 1),
        );
      },
    );
  }
  testWidgets('changing a previous answer replaces its score contribution', (
    tester,
  ) async {
    Map<String, dynamic>? submitted;
    final router = GoRouter(
      initialLocation: '/taking',
      routes: [
        GoRoute(
          path: '/taking',
          builder: (_, _) => const QuizTakingScreen(
            extra: {'id': 'gad-7', 'type': 'clinical'},
          ),
        ),
        GoRoute(
          path: AppRouter.quizResults,
          builder: (_, state) {
            submitted = Map<String, dynamic>.from(state.extra as Map);
            return const Scaffold(body: Text('Submitted'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nearly every day'));
    await tester.tap(find.text('Nearly every day'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    for (var question = 0; question < 7; question++) {
      await tester.ensureVisible(find.text('Not at all'));
      await tester.tap(find.text('Not at all'));
      await tester.pump();
      await tester.tap(find.text(question == 6 ? 'Submit' : 'Next'));
      await tester.pumpAndSettle();
    }
    expect(submitted!['score'], 0);
    expect(submitted!['answers'], List.filled(7, 0));
  });
  testWidgets(
    'first assessment requires disclaimer and cancellation does not acknowledge',
    (tester) async {
      final settings = await LocalDbService.instance.settingsBox();
      await tester.runAsync(
        () => settings.delete(ClinicalDisclaimerSheet.acknowledgementKey),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => ClinicalDisclaimerSheet.show(context),
                child: const Text('Start'),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => tester.tap(find.text('Start')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This is not a diagnosis. Talk to a professional for clinical evaluation.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(settings.get(ClinicalDisclaimerSheet.acknowledgementKey), isNull);
      await tester.runAsync(() => tester.tap(find.text('Start')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('I understand'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pumpAndSettle();
      expect(settings.get(ClinicalDisclaimerSheet.acknowledgementKey), isTrue);
      await tester.runAsync(() => tester.tap(find.text('Start')));
      await tester.pumpAndSettle();
      expect(find.text('Before we start'), findsNothing);
    },
  );
  testWidgets(
    'chooser includes both clinical cards and hides legacy assessments',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const QuizSelectionScreen()),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
      expect(find.text(ClinicalAssessment.phq9.title), findsOneWidget);
      expect(find.text(ClinicalAssessment.gad7.title), findsOneWidget);
      expect(find.text('Sleep Hygiene Check'), findsNothing);
      expect(find.text('Relationship Boundaries'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('support sheet is optional and leaves the results visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('Results'),
                TextButton(
                  onPressed: () => QuizSupportSheet.show(context),
                  child: const Text('Support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();
    expect(find.text("I'm okay right now"), findsOneWidget);
    await tester.tap(find.text("I'm okay right now"));
    await tester.pumpAndSettle();
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Support is here for you'), findsNothing);
  });
}
