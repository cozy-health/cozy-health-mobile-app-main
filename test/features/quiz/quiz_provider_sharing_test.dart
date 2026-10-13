import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/provider_share_confirm_dialog.dart';
import '../../core/widgets/widget_test_support.dart';

void main() {
  sharedWidgetTestSetup();
  testWidgets('selected-result confirmation states exactly what is shared', (
    tester,
  ) async {
    bool? accepted;
    await pumpSharedWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            accepted = await ProviderShareConfirmDialog.show(
              context,
              providerName: 'Dr. Fixture',
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('selected result'), findsOneWidget);
    expect(
      find.textContaining('future results remain private'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Individual answers are not shared'),
      findsOneWidget,
    );
    expect(accepted, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(accepted, isFalse);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share this result'));
    await tester.pumpAndSettle();
    expect(accepted, isTrue);
  });
}
