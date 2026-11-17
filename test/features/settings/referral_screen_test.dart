import 'package:cozy_health/features/settings/presentation/screens/referral_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('invitation copies a real public link without sample referrals', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(const MaterialApp(home: ReferralScreen()));
    expect(find.text('https://dev.cozyhealth.org'), findsOneWidget);
    expect(find.text('@alex'), findsNothing);
    expect(find.text('cozy.health/r/sarahchen'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('invite-copy')));
    await tester.pumpAndSettle();
    expect(copied, 'https://dev.cozyhealth.org');
  });
}
