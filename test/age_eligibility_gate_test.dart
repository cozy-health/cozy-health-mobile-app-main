import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/widgets/age_eligibility_gate.dart';
import 'package:cozy_health/core/services/age_eligibility_service.dart';

void main() {
  testWidgets('legacy wrapper never asks for age or guardian details', (
    tester,
  ) async {
    var calls = 0;
    final service = AgeEligibilityService(
      enforcement: () => true,
      fetch: () async {
        calls++;
        throw StateError('Retired endpoint');
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AgeEligibilityGate(
          service: service,
          review: true,
          child: const Text('Normal account flow'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Normal account flow'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(calls, 0);
    service.dispose();
  });
}
