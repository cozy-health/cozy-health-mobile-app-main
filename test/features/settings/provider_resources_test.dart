import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_resources_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_screen.dart';
import 'package:cozy_health/utils/screen_util.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';

Map<String, dynamic> assignment(int id) => {
  'id': id,
  'status': 'assigned',
  'notes': 'Each morning',
  'provider': {'name': 'Dr. Avery', 'practice': 'Cozy Clinic'},
  'resource': {
    'title': 'Breathing $id',
    'type': 'exercise',
    'duration_minutes': 5,
    'description': 'Slow breaths',
  },
};

class ResourceService extends Fake implements SettingsService {
  final pages = <int>[];
  final updates = <String>[];
  bool failLoad = false;
  bool failUpdate = false;
  int lastPage = 1;
  List<Map<String, dynamic>> items = [assignment(1)];
  @override
  Future<Map<String, dynamic>> getProviderResources({int page = 1}) async {
    pages.add(page);
    if (failLoad) throw StateError('Offline');
    return {'data': items, 'last_page': lastPage};
  }

  @override
  Future<Map<String, dynamic>> updateProviderResource({
    required String assignmentId,
    required String status,
  }) async {
    updates.add('$assignmentId:$status');
    if (failUpdate) throw StateError('Offline');
    return {
      'assignment': {...items.first, 'status': status},
    };
  }

  @override
  Future<Map<String, dynamic>> getProvider() async => {
    'has_provider': true,
    'provider': {
      'id': 1,
      'provider_name': 'Dr. Avery',
      'provider_verified': true,
      'consent_flags': {},
    },
  };
}

class ResourceApi extends Fake implements ApiClient {
  final calls = <Invocation>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if ([#get, #patch].contains(invocation.memberName)) {
      calls.add(invocation);
      return Future<dynamic>.value(
        Response<dynamic>(
          requestOptions: RequestOptions(path: ''),
          data: {'data': [], 'assignment': assignment(1)},
        ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

Future<void> showResources(WidgetTester tester, ResourceService service) async {
  await tester.pumpWidget(
    MaterialApp(home: ProviderResourcesScreen(settingsService: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  test('service uses patient resource routes and status body', () async {
    final api = ResourceApi();
    final service = SettingsService(apiClient: api);
    await service.getProviderResources(page: 2);
    await service.updateProviderResource(
      assignmentId: '7',
      status: 'completed',
    );
    expect(api.calls[0].positionalArguments.single, '/me/resources');
    expect(api.calls[0].namedArguments[#queryParameters], {'page': 2});
    expect(api.calls[1].positionalArguments.single, '/me/resources/7');
    expect(api.calls[1].namedArguments[#body], {'status': 'completed'});
  });
  testWidgets('shows resource details and guidance', (tester) async {
    await showResources(tester, ResourceService());
    for (final text in [
      'Breathing 1',
      'From Dr. Avery',
      'Cozy Clinic',
      'exercise · 5 min',
      'Slow breaths',
      'Provider guidance: Each morning',
      'Assigned',
    ]) {
      expect(find.text(text), findsOneWidget);
    }
  });
  testWidgets('completes assigned resource via API and updates screen', (
    tester,
  ) async {
    final service = ResourceService();
    await showResources(tester, service);
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();
    expect(service.updates, ['1:completed']);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Mark complete'), findsNothing);
  });
  testWidgets('declines assigned resource via API', (tester) async {
    final service = ResourceService();
    await showResources(tester, service);
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(service.updates, ['1:declined']);
    expect(find.text('Declined'), findsOneWidget);
  });
  testWidgets('failed mutation preserves assigned status and can retry', (
    tester,
  ) async {
    final service = ResourceService()..failUpdate = true;
    await showResources(tester, service);
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.textContaining('status has not changed'), findsOneWidget);
    service.failUpdate = false;
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();
    expect(find.text('Completed'), findsOneWidget);
  });
  testWidgets('empty state and pull refresh reload resources', (tester) async {
    final service = ResourceService()..items = [];
    await showResources(tester, service);
    expect(
      find.text('Resources assigned by your provider will appear here.'),
      findsOneWidget,
    );
    service.items = [assignment(2)];
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(service.pages, [1, 1]);
    expect(find.text('Breathing 2'), findsOneWidget);
  });
  testWidgets('loads more without replacing existing page', (tester) async {
    final service = ResourceService()..lastPage = 2;
    await showResources(tester, service);
    service.items = [assignment(2)];
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(service.pages, [1, 2]);
    expect(find.text('Breathing 1'), findsOneWidget);
    expect(find.text('Breathing 2'), findsOneWidget);
  });
  testWidgets('load error offers retry without claiming empty state', (
    tester,
  ) async {
    final service = ResourceService()..failLoad = true;
    await showResources(tester, service);
    expect(find.text('Unable to load provider resources.'), findsOneWidget);
    expect(
      find.text('Resources assigned by your provider will appear here.'),
      findsNothing,
    );
    service.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Breathing 1'), findsOneWidget);
  });
  testWidgets('My Provider Resources tab works with all consent flags off', (
    tester,
  ) async {
    final service = ResourceService();
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScreen(settingsService: service),
        builder: (context, child) {
          ScreenUtil.init(context);
          return child!;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(service.pages, isEmpty);
    await tester.ensureVisible(find.text('Resources'));
    await tester.tap(find.text('Resources'));
    await tester.pumpAndSettle();
    expect(service.pages, [1]);
    expect(find.text('Breathing 1'), findsOneWidget);
    expect(find.text('Share mood entries'), findsNothing);
    await tester.tap(find.text('Sharing'));
    await tester.pumpAndSettle();
    expect(find.text('Share mood entries'), findsOneWidget);
  });
}
