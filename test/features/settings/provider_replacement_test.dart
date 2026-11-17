import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'package:cozy_health/features/settings/presentation/widgets/provider_replacement_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

class ReplacementService extends Fake implements SettingsService {
  final requests = <String>[];
  String? cancelled;
  bool fail = false;

  @override
  Future<Map<String, dynamic>> requestProviderReplacement({
    required int originalLinkId,
    required String providerEmail,
    required String requestId,
  }) async {
    expect(originalLinkId, 4);
    expect(providerEmail, 'replacement@example.test');
    requests.add(requestId);
    if (fail) throw ApiServerException(statusCode: 503);
    return {
      'data': {'id': 8},
    };
  }

  @override
  Future<void> cancelProviderReplacement(String requestId) async {
    cancelled = requestId;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await installLocalTestFonts();
  });
  tearDown(() => networkOffline.value = false);

  Future<void> show(
    WidgetTester tester,
    ReplacementService service,
    Map<String, dynamic> state, {
    VoidCallback? changed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProviderReplacementPanel(
              originalLinkId: 4,
              state: state,
              service: service,
              onChanged: () async {
                changed?.call();
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('waiting state cannot send and explains the 168-hour rule', (
    tester,
  ) async {
    await show(tester, ReplacementService(), {'eligible': false});
    expect(find.textContaining('168 hours'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('replacement-provider-email')),
      findsNothing,
    );
  });

  testWidgets(
    'network retry reuses request identity and success refreshes state',
    (tester) async {
      final service = ReplacementService()..fail = true;
      var refreshed = 0;
      await show(tester, service, {
        'eligible': true,
      }, changed: () => refreshed++);
      await tester.enterText(
        find.byKey(const ValueKey('replacement-provider-email')),
        'replacement@example.test',
      );
      final send = find.byKey(const ValueKey('request-provider-replacement'));
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(refreshed, 0);
      service.fail = false;
      await tester.ensureVisible(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(service.requests.length, 2);
      expect(service.requests.first, service.requests.last);
      expect(refreshed, 1);
    },
  );

  testWidgets(
    'pending replacement can be cancelled without disconnecting current provider',
    (tester) async {
      final service = ReplacementService();
      await show(tester, service, {
        'eligible': false,
        'pending': {
          'id': 8,
          'request_id': 'request-fixture',
          'status': 'pending',
          'provider_email': 'replacement@example.test',
          'invitation_code': '123456',
        },
      });
      expect(find.textContaining('123456'), findsOneWidget);
      final cancel = find.byKey(const ValueKey('cancel-provider-replacement'));
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(service.cancelled, 'request-fixture');
      expect(service.requests, isEmpty);
    },
  );

  testWidgets('offline controls do not send requests', (tester) async {
    networkOffline.value = true;
    final service = ReplacementService();
    await show(tester, service, {'eligible': true});
    final send = find.byKey(const ValueKey('request-provider-replacement'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(service.requests, isEmpty);
  });

  testWidgets('expired state fits a narrow screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProviderReplacementPanel(
              originalLinkId: 4,
              state: const {
                'eligible': true,
                'pending': {'status': 'expired'},
              },
              service: ReplacementService(),
              onChanged: () async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('invitation expired'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
