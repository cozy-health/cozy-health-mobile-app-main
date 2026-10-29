import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/age_details_fields.dart';
import 'package:cozy_health/features/auth/presentation/screens/create_account_screen.dart';
import 'package:cozy_health/features/auth/presentation/widgets/auth_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/endpoint_fixture.dart';
import '../../support/local_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  setUpAll(() async {
    await fixture.open();
    await installLocalTestFonts();
  });
  setUp(fixture.reset);
  tearDownAll(() async {
    await fixture.close();
    resetLocalTestFonts();
  });

  for (final dark in [false, true]) {
    testWidgets(
      'signup needs account details and Terms, not retired age fields: dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(dark ? 2 : 1)),
                child: child!,
              ),
              home: const CreateAccountScreen(),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pumpAndSettle();
        expect(find.byType(AgeDetailsFields), findsNothing);
        expect(find.byType(AuthTextField), findsNWidgets(4));
        final button = find.byType(AuthPrimaryButton);
        expect(tester.widget<AuthPrimaryButton>(button).onPressed, isNull);

        Future<void> enter(String label, String value) async {
          final field = find.descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is AuthTextField && widget.label == label,
            ),
            matching: find.byType(TextField),
          );
          await tester.ensureVisible(field);
          await tester.enterText(field, value);
          await tester.pump();
        }

        await enter('Full Name', 'Test Person');
        await enter('Email', 'signup@example.test');
        await enter('Password', 'Synthetic-pass123');
        await enter('Confirm Password', 'Synthetic-pass123');
        expect(tester.widget<AuthPrimaryButton>(button).onPressed, isNull);
        final terms = find.byType(Checkbox).first;
        await tester.ensureVisible(terms);
        await tester.tap(terms);
        await tester.pumpAndSettle();
        expect(tester.widget<AuthPrimaryButton>(button).onPressed, isNotNull);
        expect(find.text('Email available'), findsNothing);
        expect(fixture.requests, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
