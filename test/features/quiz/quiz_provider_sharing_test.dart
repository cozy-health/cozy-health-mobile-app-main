import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/provider_share_confirm_dialog.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import '../../core/widgets/widget_test_support.dart';

class _SharingSettings extends SettingsService {
  _SharingSettings({this.linked = true});
  final bool linked;
  final List<Map<String, dynamic>> updates = [];
  @override
  Future<Map<String, dynamic>> getProvider() async => {
    'has_provider': linked,
    'provider': linked
        ? {
            'link_id': '42',
            'provider_name': 'Linked clinician',
            'status': 'verified',
            'consent_flags': {'quizzes': false},
          }
        : null,
  };
  @override
  Future<void> updateConsent({
    required String linkId,
    required String consentType,
    required bool value,
  }) async {
    updates.add({
      'link_id': linkId,
      'consent_type': consentType,
      'value': value,
    });
  }
}

void main() {
  sharedWidgetTestSetup();
  Future<void> open(WidgetTester tester, _SharingSettings settings) async {
    await pumpSharedWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              QuizProviderSharing.share(context, service: settings),
          child: const Text('Share'),
        ),
      ),
    );
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'requires explicit consent and sends no score or answers to consent API',
    (tester) async {
      final settings = _SharingSettings();
      await open(tester, settings);
      expect(find.textContaining('past and future results'), findsOneWidget);
      expect(
        find.textContaining('Individual answers are not shared'),
        findsOneWidget,
      );
      expect(settings.updates, isEmpty);
      await tester.tap(find.text('Enable sharing'));
      await tester.pumpAndSettle();
      expect(settings.updates, [
        {'link_id': '42', 'consent_type': 'quizzes', 'value': true},
      ]);
    },
  );
  testWidgets('cancelling never updates consent', (tester) async {
    final settings = _SharingSettings();
    await open(tester, settings);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(settings.updates, isEmpty);
  });
  testWidgets('unlinked users cannot share results', (tester) async {
    final settings = _SharingSettings(linked: false);
    await open(tester, settings);
    expect(find.text('Enable sharing'), findsNothing);
    expect(settings.updates, isEmpty);
    expect(find.textContaining('Link and verify a provider'), findsOneWidget);
  });
}
