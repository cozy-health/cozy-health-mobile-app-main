import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'provider_record_picker_test.dart' show PickerApi;
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/constants/api_constants.dart';
import 'package:cozy_health/features/settings/data/settings_service.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_hub_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';

class MessagingApi extends Fake implements ApiClient {
  bool connected = true, failSend = false;
  final sent = <Map<String, dynamic>>[];
  final reads = <String>[];
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
    reads.add(path);
    if (path == ApiConstants.provider) {
      return response({
        'has_provider': connected,
        'provider': connected ? {'id': 3, 'name': 'Dr. Avery'} : null,
      });
    }
    if (path == '/me/resources') {
      return response({
        'data': [
          {
            'id': 'resource-1',
            'resource': {'title': 'A saved exercise'},
          },
        ],
        'last_page': 1,
      });
    }
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

class PreviewMessagingApi extends MessagingApi {
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    if (path == '/provider-conversations') {
      return response([
        {
          'id': 1,
          'name': 'Dr. Avery',
          'consent_flags': {'moods': true},
        },
        {
          'id': 2,
          'name': 'Dr. Jordan',
          'consent_flags': {'moods': true},
        },
      ]);
    }
    if (path.endsWith('/records')) return PickerApi().get(path, query: query);
    return super.get(
      path,
      queryParameters: queryParameters,
      query: query,
      withAuth: withAuth,
      options: options,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    await installLocalTestFonts();
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('provider_cache_test');
    Hive.init(directory.path);
    await LocalDbService().settingsBox();
  });
  setUp(() async {
    networkOffline.value = false;
    await (await LocalDbService().settingsBox()).clear();
  });
  tearDownAll(() async {
    resetLocalTestFonts();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'linked provider and assigned resource reads survive offline reopening',
    () async {
      final api = MessagingApi();
      final service = SettingsService(apiClient: api);
      final provider = await service.getProvider();
      final resources = await service.getProviderResources();
      final settings = await LocalDbService().settingsBox();
      await settings.close();
      await LocalDbService().settingsBox();
      networkOffline.value = true;
      expect(await service.getProvider(), provider);
      expect(await service.getProviderResources(), resources);
      expect(api.reads.length, 2);
      await expectLater(
        service.requestProvider(providerEmail: 'provider@example.test'),
        throwsA(isA<ApiNetworkException>()),
      );
      await expectLater(
        service.updateProviderResource(
          assignmentId: 'resource-1',
          status: 'completed',
        ),
        throwsA(isA<ApiNetworkException>()),
      );
      expect(api.sent, isEmpty);
    },
  );

  Future<void> flushCache(WidgetTester tester) async {
    final box = await LocalDbService().settingsBox();
    var done = false;
    box.close().then((_) => done = true);
    for (var i = 0; i < 100 && !done; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    expect(done, isTrue);
    await tester.runAsync(() => LocalDbService().settingsBox());
  }

  testWidgets(
    'cached provider messages reopen offline and sending stays disabled',
    (tester) async {
      final settings = await LocalDbService().settingsBox();
      await tester.runAsync(
        () => settings.put('provider_conversations_v1', {
          'threads': [
            {
              'id': 1,
              'name': 'Dr. Avery',
              'consent_flags': {'moods': true},
            },
          ],
          'messages': {
            '1': [
              {
                'id': 1,
                'sender': 'provider',
                'content': 'Saved care message',
                'records': [],
              },
            ],
          },
        }),
      );
      networkOffline.value = true;
      final api = MessagingApi();
      await tester.runAsync(
        () => tester.pumpWidget(
          MaterialApp(home: ProviderHubScreen(apiClient: api)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Saved care message'), findsOneWidget);
      expect(
        tester
            .widget<AppPressable>(find.byKey(const ValueKey('provider-send')))
            .onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(api.sent, isEmpty);
      await tester.runAsync(() => tester.pumpWidget(const SizedBox()));
      await flushCache(tester);
      networkOffline.value = null;
    },
  );
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
      await tester.runAsync(
        () => tester.pumpWidget(
          MaterialApp(home: ProviderHubScreen(apiClient: api)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared by Taylor'), findsOneWidget);
      expect(find.text('Feeling calm'), findsOneWidget);
      expect(find.textContaining('2026-10-17'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('provider-tab-1')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shared by Taylor'), findsOneWidget);
      expect(find.text('Feeling calm'), findsOneWidget);
      expect(find.textContaining('2026-10-17'), findsNothing);
      await tester.runAsync(() => tester.pumpWidget(const SizedBox()));
      await flushCache(tester);
    },
  );
  testWidgets('unconnected users see provider connection action', (
    tester,
  ) async {
    final api = MessagingApi()..connected = false;
    await tester.runAsync(
      () => tester.pumpWidget(
        MaterialApp(home: ProviderHubScreen(apiClient: api)),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connect provider'), findsOneWidget);
    expect(find.text('Assistant'), findsNothing);
    await tester.runAsync(() => tester.pumpWidget(const SizedBox()));
    await flushCache(tester);
  });
  testWidgets(
    'failed sends preserve draft and retry with the same message identifier',
    (tester) async {
      final api = MessagingApi()..failSend = true;
      await tester.runAsync(
        () => tester.pumpWidget(
          MaterialApp(home: ProviderHubScreen(apiClient: api)),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Hello doctor');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('provider-send')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello doctor'), findsOneWidget);
      expect(find.text('Retry send'), findsOneWidget);
      // Successful polling must not dismiss an unconfirmed send.
      await tester.pump(const Duration(seconds: 6));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry send'), findsOneWidget);
      api.failSend = false;
      await tester.tap(find.text('Retry send'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(api.sent.length, 2);
      expect(api.sent[0]['client_id'], api.sent[1]['client_id']);
      expect(find.text('Hello doctor'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.runAsync(() => tester.pumpWidget(const SizedBox()));
      await flushCache(tester);
    },
  );
  testWidgets(
    'provider chooser preserves selection and open record preview clears on account change',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const captureKey = ValueKey('provider-popup-capture');
      Future<void> drive() async {
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> capture(String name) async {
        await tester.pump();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 2);
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          await Directory(
            'docs/design/approved-popups-implemented',
          ).create(recursive: true);
          await File(
            'docs/design/approved-popups-implemented/$name.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          img.dispose();
        });
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              RepaintBoundary(key: captureKey, child: child!),
          home: ProviderHubScreen(apiClient: PreviewMessagingApi()),
        ),
      );
      await drive();
      await tester.tap(find.bySemanticsLabel('Choose provider, Dr. Avery'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a provider'), findsOneWidget);
      await capture('provider-chooser-light-blue');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Choose provider, Dr. Avery'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Share a record'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mood check-in').last);
      await drive();
      expect(find.text('Feeling calm'), findsOneWidget);
      await tester.tap(find.text('Select record'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Preview ')));
      await tester.pumpAndSettle();
      expect(find.text('Record preview'), findsOneWidget);
      expect(find.text('Feeling calm'), findsOneWidget);
      await capture('record-preview-light-blue');
      await flushCache(tester);
      await tester.runAsync(
        () => LocalDbService().activateAccount('guest_popup_review'),
      );
      await drive();
      expect(find.text('Feeling calm'), findsNothing);
      expect(find.textContaining('Close this preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await flushCache(tester);
    },
  );
}
