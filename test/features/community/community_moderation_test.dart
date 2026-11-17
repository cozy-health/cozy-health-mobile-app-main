import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/community/data/community_moderation_state.dart';
import 'package:cozy_health/features/community/presentation/screens/community_moderation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';

class ModerationFixture extends CommunityModerationState {
  ModerationFixture() : super.testing() {
    data = {
      'active_ban': {'reason': 'Synthetic reason'},
      'decisions': [
        {
          'id': 'decision-one',
          'kind': 'ban',
          'reason': 'Synthetic reason',
          'status': 'active',
          'expires_at': null,
        },
      ],
      'appeals': <Map<String, dynamic>>[],
    };
  }
  bool fail = false;
  final submissions = <String>[];
  @override
  Future<void> refresh() async {
    notifyListeners();
  }

  @override
  Future<void> appeal(String decision, String message) async {
    submissions.add(message);
    if (fail) throw StateError('Synthetic outage');
    data!['appeals'] = [
      {'decision_id': decision, 'status': 'pending'},
    ];
    notifyListeners();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await installLocalTestFonts();
  });
  Future<void> show(
    WidgetTester tester,
    ModerationFixture fixture, {
    bool dark = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: CommunityModerationScreen(state: fixture),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows reason, keeps failed appeal draft and avoids a second appeal form after success',
    (tester) async {
      final fixture = ModerationFixture();
      await show(tester, fixture);
      expect(find.text('Synthetic reason'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Please review the restriction.',
      );
      fixture.fail = true;
      await tester.ensureVisible(find.text('Submit appeal'));
      await tester.tap(find.text('Submit appeal'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not submit the appeal. Your text is preserved; refresh and retry.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Please review the restriction.',
      );
      fixture.fail = false;
      await tester.ensureVisible(find.text('Submit appeal'));
      await tester.tap(find.text('Submit appeal'));
      await tester.pumpAndSettle();
      expect(find.text('Appeal: pending'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(fixture.submissions, [
        'Please review the restriction.',
        'Please review the restriction.',
      ]);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'moderation is usable at 200 percent text on a narrow screen dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await show(tester, ModerationFixture(), dark: dark, scale: 2);
        await tester.scrollUntilVisible(find.text('Submit appeal'), 250);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Submit appeal'), findsOneWidget);
      },
    );
  }
}
