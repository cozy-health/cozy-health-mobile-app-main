import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/features/settings/presentation/widgets/provider_record_picker.dart';
import '../../support/local_fonts.dart';

class PickerApi extends Fake implements ApiClient {
  final pages = <int>[];
  bool fail = false;
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    final page = query!['page'] as int;
    pages.add(page);
    if (fail) throw StateError('Unavailable');
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'data': [
          {
            'id': 'mood-$page',
            'type': 'moods',
            'data': {
              'mood': page == 1 ? 'calm' : 'happy',
              'created_at': '2026-10-22',
            },
          },
        ],
        'current_page': page,
        'last_page': 2,
      },
    );
  }
}

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  testWidgets(
    'load more stays in the same sheet and keeps first page records private',
    (tester) async {
      final api = PickerApi();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ProviderRecordPicker(
                    api: api,
                    path: '/provider-conversations/1',
                    type: 'moods',
                    title: 'mood check-in',
                    isCurrent: () => true,
                    selected: const [],
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final route = ModalRoute.of(
        tester.element(find.byType(ProviderRecordPicker)),
      );
      expect(find.text('Feeling calm'), findsOneWidget);
      expect(find.textContaining('2026-10-22'), findsNothing);
      await tester.ensureVisible(find.text('Load more records'));
      await tester.tap(find.text('Load more records'));
      await tester.pumpAndSettle();
      expect(
        ModalRoute.of(tester.element(find.byType(ProviderRecordPicker))),
        same(route),
      );
      expect(api.pages, [1, 2]);
      expect(find.text('Feeling happy'), findsOneWidget);
      expect(find.textContaining('mood-1'), findsNothing);
      expect(find.textContaining('mood-2'), findsNothing);
    },
  );
  testWidgets(
    'changing the originating account clears private picker previews',
    (tester) async {
      final scope = ValueNotifier<int>(0);
      var current = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderRecordPicker(
              api: PickerApi(),
              path: '/provider-conversations/1',
              type: 'moods',
              title: 'mood check-in',
              isCurrent: () => current,
              selected: const [],
              scopeChanges: scope,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Feeling calm'), findsOneWidget);
      current = false;
      scope.value++;
      await tester.pump();
      expect(find.text('Feeling calm'), findsNothing);
      expect(
        find.textContaining('account or conversation changed'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      scope.dispose();
    },
  );
}
