import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/widgets/age_details_fields.dart';

void main() {
  testWidgets(
    'date selection and searchable country selection update the signup values',
    (tester) async {
      final dob = TextEditingController(), country = TextEditingController();
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AgeDetailsFields(
                  dob: dob,
                  country: country,
                  onChanged: () => changes++,
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Date of birth'), findsOneWidget);
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(dob.text, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      final countryField = find.descendant(
        of: find.byType(DropdownMenu<String>),
        matching: find.byType(TextField),
      );
      await tester.tap(countryField);
      await tester.enterText(countryField, 'Nigeria');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nigeria').hitTestable().last);
      await tester.pumpAndSettle();
      expect(country.text, 'NG');
      expect(changes, 2);
      await tester.pumpWidget(const SizedBox.shrink());
      dob.dispose();
      country.dispose();
    },
  );

  testWidgets(
    'age fields remain labeled and fit a narrow screen at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final dob = TextEditingController(), country = TextEditingController();
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AgeDetailsFields(
                    dob: dob,
                    country: country,
                    onChanged: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      dob.dispose();
      country.dispose();
    },
  );
}
