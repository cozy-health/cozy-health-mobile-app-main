import '../../support/local_fonts.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/wellness_sheet.dart';
import 'package:cozy_health/features/journal/presentation/widgets/journal_share_flow.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/surface_capture.dart';

class ShareApi extends Fake implements ApiClient {
  bool connected = true,
      consent = true,
      fail = false,
      conflict = false,
      changed = false;
  final sent = <Map<String, dynamic>>[];
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
                  'id': 7,
                  'name': 'Provider One',
                  'consent_flags': {'journals': consent},
                },
                {
                  'id': 8,
                  'name': 'Provider Two',
                  'consent_flags': {'journals': true},
                },
              ]
            : [],
      );
    }
    expect(path, '/provider-conversations/7/journal-shares/preview');
    expect(
      (query ?? queryParameters)?['journal_id'],
      '11111111-1111-4111-8111-111111111111',
    );
    return response({
      'revision': 'a' * 64,
      'entry': {
        'title': 'Reflection',
        'body': changed ? 'Old server copy' : 'Private written entry',
      },
    });
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
    expect(path, '/provider-conversations/7/journal-shares');
    sent.add(Map<String, dynamic>.from(body as Map));
    if (conflict) throw ApiServerException(statusCode: 409);
    if (fail) throw ApiNetworkException();
    return response({'share_id': '22222222-2222-4222-8222-222222222222'});
  }
}

class CopyApi extends Fake implements ApiClient {
  bool withdrawn = false;
  int deletions = 0;
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    if (withdrawn) throw ApiServerException(statusCode: 404);
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: {
        'entry': {
          'title': 'Shared reflection',
          'body': 'Confirmed shared copy',
        },
      },
    );
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
    deletions++;
    withdrawn = true;
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      data: {},
    );
  }
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  late ShareApi api;
  final entry = JournalEntry(
    id: '11111111-1111-4111-8111-111111111111',
    type: 'free',
    title: 'Reflection',
    body: 'Private written entry',
    wordCount: 3,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    api = ShareApi();
  });
  Future<void> open(
    WidgetTester tester, {
    bool dark = false,
    bool narrow = false,
  }) async {
    tester.view.physicalSize = narrow
        ? const Size(320, 568)
        : const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(narrow ? 2 : 1)),
          child: RepaintBoundary(key: surfaceCaptureKey, child: child!),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showJournalShareFlow(
                context,
                entry,
                apiClient: api,
                sync: () async {},
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Provider One'));
    await tester.tap(find.text('Provider One'));
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets(
      'review names recipient and shares only after explicit confirmation dark=$dark',
      (tester) async {
        await open(tester, dark: dark);
        expect(api.sent, isEmpty);
        await choose(tester);
        expect(api.sent, isEmpty);
        expect(find.text('Share with Provider One'), findsOneWidget);
        expect(find.text('Private written entry'), findsOneWidget);
        await captureSurface(
          tester,
          'journal-share-preview-${dark ? 'dark' : 'light'}',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('confirm-journal-share')),
        );
        await tester.tap(find.byKey(const ValueKey('confirm-journal-share')));
        await tester.pumpAndSettle();
        expect(api.sent.single['confirmed'], isTrue);
        expect(api.sent.single.containsKey('body'), isFalse);
        expect(api.sent.single.containsKey('audio'), isFalse);
        expect(find.text('Entry shared'), findsOneWidget);
      },
    );
  }
  testWidgets('network retry keeps confirmation id and revision', (
    tester,
  ) async {
    api.fail = true;
    await open(tester);
    await choose(tester);
    await tester.tap(find.text('Share this copy'));
    await tester.pumpAndSettle();
    expect(api.sent, hasLength(1));
    api.fail = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(api.sent, hasLength(2));
    expect(api.sent[0], api.sent[1]);
  });
  testWidgets('changed revision requires fresh review', (tester) async {
    api.conflict = true;
    await open(tester);
    await choose(tester);
    await tester.tap(find.text('Share this copy'));
    await tester.pumpAndSettle();
    expect(find.text('Share this copy'), findsNothing);
    expect(find.textContaining('Review again'), findsOneWidget);
  });
  testWidgets('server copy must match saved local text', (tester) async {
    api.changed = true;
    await open(tester);
    await choose(tester);
    expect(find.text('Share this copy'), findsNothing);
    expect(api.sent, isEmpty);
  });
  testWidgets('missing provider and consent use centred notices', (
    tester,
  ) async {
    api.connected = false;
    await open(tester);
    expect(find.text('Connect a provider first'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await captureSurface(tester, 'journal-connect-provider');
    await tester.tap(find.byKey(const ValueKey('wellness-sheet-close')));
    await tester.pumpAndSettle();
    api.connected = true;
    api.consent = false;
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await choose(tester);
    expect(find.text('Journal sharing is off'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    expect(api.sent, isEmpty);
    await captureSurface(tester, 'journal-sharing-off');
  });
  testWidgets('large text keeps confirmation reachable on small phones', (
    tester,
  ) async {
    await open(tester, narrow: true);
    await choose(tester);
    await tester.scrollUntilVisible(
      find.text('Share this copy'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Share this copy').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureSurface(tester, 'journal-sharing-large-text');
  });
  testWidgets('account switch removes the previous preview', (tester) async {
    await open(tester);
    await choose(tester);
    await TokenStorage().saveToken('new-account', stayLoggedIn: false);
    await tester.pumpAndSettle();
    expect(find.text('Private written entry'), findsNothing);
    expect(api.sent, isEmpty);
  });
  Future<void> openCopy(WidgetTester tester, CopyApi copyApi) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showWellnessDialog<void>(
                context: context,
                builder: (_) => SharedJournalCopyView(
                  linkId: '7',
                  shareId: 'copy',
                  apiClient: copyApi,
                ),
              ),
              child: const Text('Open copy'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open copy'));
    await tester.pumpAndSettle();
  }

  testWidgets('withdrawal requires confirmation and removes confirmed text', (
    tester,
  ) async {
    final copyApi = CopyApi();
    await openCopy(tester, copyApi);
    expect(find.text('Confirmed shared copy'), findsOneWidget);
    await tester.ensureVisible(find.text('Stop sharing this copy'));
    await tester.tap(find.text('Stop sharing this copy'));
    await tester.pumpAndSettle();
    expect(copyApi.deletions, 0);
    await tester.tap(find.text('Stop sharing'));
    await tester.pumpAndSettle();
    expect(copyApi.deletions, 1);
    expect(find.text('Confirmed shared copy'), findsNothing);
    await tester.tap(find.text('Refresh copy'));
    await tester.pumpAndSettle();
    expect(find.text('Confirmed shared copy'), findsNothing);
  });
  testWidgets('account switch closes shared copy and withdrawal confirmation', (
    tester,
  ) async {
    final copyApi = CopyApi();
    await openCopy(tester, copyApi);
    await tester.tap(find.text('Stop sharing this copy'));
    await tester.pumpAndSettle();
    await TokenStorage().saveToken('another-account', stayLoggedIn: false);
    await tester.pumpAndSettle();
    expect(find.text('Confirmed shared copy'), findsNothing);
    expect(find.text('Stop sharing'), findsNothing);
    expect(copyApi.deletions, 0);
  });
}
