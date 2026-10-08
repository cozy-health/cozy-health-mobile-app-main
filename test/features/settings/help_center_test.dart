import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cozy_health/core/routing/app_router.dart';
import 'package:cozy_health/features/settings/presentation/screens/help_center_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/help_support_screen.dart';
import '../../support/local_fonts.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  test(
    'FAQ catalog has twenty unique questions in all six requested categories',
    () {
      expect(helpFaqs.length, 20);
      expect(helpFaqs.map((item) => item.question).toSet().length, 20);
      expect(
        {
          for (final category in helpFaqs.map((item) => item.category).toSet())
            category: helpFaqs
                .where((item) => item.category == category)
                .length,
        },
        {
          'Getting Started': 3,
          'Mood & Journal': 4,
          'Crisis Resources': 4,
          'Privacy & Data': 3,
          'Account': 3,
          'Community': 3,
        },
      );
    },
  );
  testWidgets(
    'existing support route renders the new center and expands answers',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
      expect(find.text('Help center'), findsOneWidget);
      expect(find.text(helpFaqs.first.answer), findsNothing);
      await tester.tap(find.text(helpFaqs.first.question));
      await tester.pumpAndSettle();
      expect(find.text(helpFaqs.first.answer), findsOneWidget);
    },
  );
  testWidgets('search filters questions and clear restores the catalog', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HelpCenterScreen()));
    await tester.enterText(find.byType(TextField), 'immediate danger');
    await tester.pumpAndSettle();
    expect(
      find.text('What if someone is in immediate danger?'),
      findsOneWidget,
    );
    expect(find.text(helpFaqs.first.question), findsNothing);
    await tester.enterText(find.byType(TextField), 'unmatched query');
    await tester.pumpAndSettle();
    expect(find.text('No questions match your search.'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text(helpFaqs.first.question), findsOneWidget);
  });
  testWidgets('report problem CTA preserves support navigation', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRouter.helpSupport,
      routes: [
        GoRoute(
          path: AppRouter.helpSupport,
          builder: (_, __) => const HelpSupportScreen(),
        ),
        GoRoute(
          path: AppRouter.reportProblem,
          builder: (_, __) => const Scaffold(body: Text('Report destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.enterText(find.byType(TextField), 'unmatched query');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Report a problem'));
    await tester.tap(find.text('Report a problem'));
    await tester.pumpAndSettle();
    expect(find.text('Report destination'), findsOneWidget);
  });
}
