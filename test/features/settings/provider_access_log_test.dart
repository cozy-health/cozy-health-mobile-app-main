import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_access_log_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class LogService extends Fake implements SettingsService {
  final pages = <int>[];
  bool fail = false;
  List<Map<String, dynamic>> events = [
    {
      'id': 1,
      'provider': {'name': 'Dr. Avery', 'practice': 'Cozy Clinic'},
      'action': 'list',
      'resource_type': 'mood',
      'created_at': '2026-10-01T10:00:00Z',
    },
  ];
  int lastPage = 1;

  @override
  Future<Map<String, dynamic>> getProviderAccessLog({int page = 1}) async {
    pages.add(page);
    if (fail) throw StateError('Unavailable');
    return {'data': events, 'current_page': page, 'last_page': lastPage};
  }
}

class LogApi extends Fake implements ApiClient {
  Invocation? request;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #get) {
      request = invocation;
      return Future<dynamic>.value(
        Response<dynamic>(
          requestOptions: RequestOptions(path: '/me/provider-access-log'),
          data: {'data': [], 'current_page': 2, 'last_page': 2},
        ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

Future<void> showLog(WidgetTester tester, LogService service) async {
  await tester.pumpWidget(
    MaterialApp(home: ProviderAccessLogScreen(settingsService: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'service loads the patient audit endpoint with page parameter',
    () async {
      final api = LogApi();
      final response = await SettingsService(
        apiClient: api,
      ).getProviderAccessLog(page: 2);
      expect(
        api.request!.positionalArguments.single,
        '/me/provider-access-log',
      );
      expect(api.request!.namedArguments[#queryParameters], {'page': 2});
      expect(response['current_page'], 2);
    },
  );

  testWidgets('screen shows which provider, action, and when', (tester) async {
    final service = LogService();
    await showLog(tester, service);
    expect(service.pages, [1]);
    expect(find.text('Dr. Avery'), findsOneWidget);
    expect(find.text('Cozy Clinic'), findsOneWidget);
    expect(find.text('Viewed your mood entries'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.text('No provider has accessed your data yet.'), findsNothing);
  });

  testWidgets('empty log displays the requested empty state', (tester) async {
    await showLog(tester, LogService()..events = []);
    expect(
      find.text('No provider has accessed your data yet.'),
      findsOneWidget,
    );
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('pull to refresh replaces stale events', (tester) async {
    final service = LogService();
    await showLog(tester, service);
    service.events = [
      {
        'id': 2,
        'provider': {'name': 'Dr. New', 'practice': null},
        'action': 'create',
        'resource_type': 'note',
        'created_at': '2026-10-02T12:00:00Z',
      },
    ];
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(service.pages, [1, 1]);
    expect(find.text('Dr. Avery'), findsNothing);
    expect(find.text('Dr. New'), findsOneWidget);
    expect(find.text('Added provider notes'), findsOneWidget);
  });

  testWidgets(
    'pagination loads older events without replacing the first page',
    (tester) async {
      final service = LogService()..lastPage = 2;
      await showLog(tester, service);
      service.events = [
        {
          'id': 2,
          'provider': {'name': 'Dr. Older'},
          'action': 'view',
          'resource_type': 'consent',
          'created_at': '2026-09-01T10:00:00Z',
        },
      ];
      await tester.tap(find.text('Load more'));
      await tester.pumpAndSettle();
      expect(service.pages, [1, 2]);
      expect(find.text('Dr. Avery'), findsOneWidget);
      expect(find.text('Dr. Older'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
    },
  );

  testWidgets('failed request has retry and never claims the log is empty', (
    tester,
  ) async {
    final service = LogService()..fail = true;
    await showLog(tester, service);
    expect(find.text('Unable to load provider access log.'), findsOneWidget);
    expect(find.text('No provider has accessed your data yet.'), findsNothing);
    service.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Dr. Avery'), findsOneWidget);
    expect(service.pages, [1, 1]);
  });
}
