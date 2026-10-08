import 'dart:async';

import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_screen.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/local_fonts.dart';

class ConsentApi extends Fake implements ApiClient {
  final calls = <String>[];
  final flags = <String, bool>{
    'moods': true,
    'journals': false,
    'quizzes': true,
    'notes': false,
  };
  bool revoked = false;
  bool failPatch = false;
  Completer<void>? patchGate;

  Response<dynamic> response(dynamic data) => Response<dynamic>(
    requestOptions: RequestOptions(path: ''),
    data: data,
  );

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    calls.add('GET $path');
    return response({
      'has_provider': !revoked,
      'provider': revoked
          ? null
          : {
              'id': 42,
              'link_id': 42,
              'provider_name': 'Dr. Avery',
              'provider_email': 'avery@example.test',
              'provider_verified': true,
              'status': 'verified',
              'consent_flags': {...flags},
            },
    });
  }

  @override
  Future<dynamic> patch(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    calls.add('PATCH $path');
    if (patchGate != null) await patchGate!.future;
    if (failPatch) throw StateError('Failed request');
    final payload = (data ?? body) as Map;
    flags[payload['consent_type'] as String] = payload['value'] as bool;
    return response({
      'link': {
        'consent_flags': {...flags},
      },
    });
  }

  @override
  Future<dynamic> delete(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    calls.add('DELETE $path');
    revoked = true;
    return response({'message': 'Provider access revoked.'});
  }
}

Future<GoRouter> showProvider(WidgetTester tester, ConsentApi api) async {
  final service = SettingsService(apiClient: api);
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/provider'),
            child: const Text('Settings destination'),
          ),
        ),
      ),
      GoRoute(
        path: '/provider',
        builder: (context, state) => ProviderScreen(settingsService: service),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) {
        ScreenUtil.init(context);
        return child!;
      },
    ),
  );
  await tester.tap(find.text('Settings destination'));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  test('toggle persists through the specified PATCH API payload', () async {
    final api = ConsentApi();
    await SettingsService(
      apiClient: api,
    ).updateConsent(linkId: '42', consentType: 'notes', value: true);
    expect(api.calls, ['PATCH /me/provider/42/consent']);
    expect(api.flags['notes'], isTrue);
  });

  testWidgets('screen shows provider and correct current state on load', (
    tester,
  ) async {
    final api = ConsentApi();
    final router = await showProvider(tester, api);
    addTearDown(router.dispose);
    expect(api.calls, contains('GET /provider'));
    expect(find.text('Dr. Avery'), findsOneWidget);
    expect(find.text('Link verified • Provider verified'), findsOneWidget);
    for (final entry in api.flags.entries) {
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(ValueKey('consent-${entry.key}')),
      );
      expect(toggle.value, entry.value);
    }
  });

  testWidgets(
    'toggle persists immediately and screen reflects backend on reopening',
    (tester) async {
      final api = ConsentApi();
      final router = await showProvider(tester, api);
      addTearDown(router.dispose);
      final toggle = find.byKey(const ValueKey('consent-notes'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(api.calls, contains('PATCH /me/provider/42/consent'));
      expect(api.flags['notes'], isTrue);
      router.pop();
      await tester.pumpAndSettle();
      router.push('/provider');
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    },
  );

  testWidgets('failed toggle retains prior value and offers retry', (
    tester,
  ) async {
    final api = ConsentApi()..failPatch = true;
    final router = await showProvider(tester, api);
    addTearDown(router.dispose);
    final toggle = find.byKey(const ValueKey('consent-moods'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(
      find.text(
        'Unable to save consent. Your sharing setting has not changed.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('all consent switches are disabled while a change is saving', (
    tester,
  ) async {
    final api = ConsentApi()..patchGate = Completer<void>();
    final router = await showProvider(tester, api);
    addTearDown(router.dispose);
    final toggle = find.byKey(const ValueKey('consent-moods'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();
    expect(tester.widget<SwitchListTile>(toggle).onChanged, isNull);
    api.patchGate!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('revoke calls DELETE, clears state, and returns to Settings', (
    tester,
  ) async {
    final api = ConsentApi();
    final router = await showProvider(tester, api);
    addTearDown(router.dispose);
    await tester.ensureVisible(find.text('Revoke access'));
    await tester.tap(find.text('Revoke access'));
    await tester.pumpAndSettle();
    expect(find.text('Revoke provider access?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Revoke access'));
    await tester.pumpAndSettle();
    expect(api.calls, contains('DELETE /me/provider/42'));
    expect(api.revoked, isTrue);
    expect(find.text('Settings destination'), findsOneWidget);
    router.push('/provider');
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('Dr. Avery'), findsNothing);
  });

  testWidgets('cancelled revocation sends no DELETE', (tester) async {
    final api = ConsentApi();
    final router = await showProvider(tester, api);
    addTearDown(router.dispose);
    await tester.ensureVisible(find.text('Revoke access'));
    await tester.tap(find.text('Revoke access'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(api.revoked, isFalse);
    expect(api.calls.where((call) => call.startsWith('DELETE')), isEmpty);
  });
}
