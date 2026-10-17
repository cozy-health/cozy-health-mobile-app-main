import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_hub_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';

class MessagingApi extends Fake implements ApiClient {
  bool connected = true, failSend = false;
  final sent = <Map<String, dynamic>>[];
  final messages = <Map<String, dynamic>>[];
  Response<dynamic> response(dynamic value) => Response(
    requestOptions: RequestOptions(path: ''),
    data: value,
  );
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    if (path == '/provider-conversations') {
      return response(
        connected
            ? [
                {
                  'id': 1,
                  'name': 'Dr. Avery',
                  'consent_flags': {'moods': true},
                },
              ]
            : [],
      );
    }
    if (path.endsWith('/messages')) {
      return response({'data': messages, 'has_more': false});
    }
    return response({'data': [], 'last_page': 1});
  }

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    bool withAuth = true,
    Options? options,
  }) async {
    if (path.endsWith('/messages')) {
      sent.add(Map<String, dynamic>.from(body as Map));
      if (failSend) throw StateError('Offline');
      messages.add({
        'id': 1,
        'sender': 'patient',
        'content': body['content'],
        'records': [],
        'created_at': '2026-10-16T12:00:00Z',
      });
    }
    return response({'id': 1});
  }
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  testWidgets(
    'shared records use the same named card in chat and history without dates',
    (tester) async {
      final api = MessagingApi();
      api.messages.add({
        'id': 1,
        'sender': 'patient',
        'content': '',
        'created_at': '2026-10-17T12:00:00Z',
        'records': [
          {
            'id': 'mood-1',
            'type': 'moods',
            'owner': {'name': 'Taylor', 'initials': 'T'},
            'data': {
              'mood': 'calm',
              'intensity': 3,
              'created_at': '2026-10-17T11:00:00Z',
            },
          },
        ],
      });
      await tester.pumpWidget(
        MaterialApp(home: ProviderHubScreen(apiClient: api)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared by Taylor'), findsOneWidget);
      expect(find.text('Feeling calm'), findsOneWidget);
      expect(find.textContaining('2026-10-17'), findsNothing);
      await tester.tap(find.text('Shared history'));
      await tester.pumpAndSettle();
      expect(find.text('Shared by Taylor'), findsOneWidget);
      expect(find.text('Feeling calm'), findsOneWidget);
      expect(find.textContaining('2026-10-17'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('unconnected users see provider connection action', (
    tester,
  ) async {
    final api = MessagingApi()..connected = false;
    await tester.pumpWidget(
      MaterialApp(home: ProviderHubScreen(apiClient: api)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connect provider'), findsOneWidget);
    expect(find.text('Assistant'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'failed sends preserve draft and retry with the same message identifier',
    (tester) async {
      final api = MessagingApi()..failSend = true;
      await tester.pumpWidget(
        MaterialApp(home: ProviderHubScreen(apiClient: api)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Hello doctor');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text('Hello doctor'), findsOneWidget);
      expect(find.text('Retry send'), findsOneWidget);
      api.failSend = false;
      await tester.tap(find.text('Retry send'));
      await tester.pumpAndSettle();
      expect(api.sent.length, 2);
      expect(api.sent[0]['client_id'], api.sent[1]['client_id']);
      expect(find.text('Hello doctor'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
