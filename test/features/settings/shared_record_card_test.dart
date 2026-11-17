import 'package:cozy_health/features/settings/presentation/widgets/shared_record_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';

Map<String, dynamic> record(String type, Map<String, dynamic> data) => {
  'type': type,
  'id': 'record-1',
  'owner': {'name': 'Taylor', 'initials': 'T'},
  'data': {
    ...data,
    'created_at': '2026-10-17T12:00:00Z',
    'completed_at': '2026-10-17T12:00:00Z',
  },
};

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  final examples = {
    'moods': record('moods', {
      'mood': 'calm',
      'intensity': 3,
      'note': 'A slower morning helped me feel more grounded today.',
    }),
    'journals': record('journals', {
      'title': 'Making room for myself',
      'type': 'text',
      'word_count': 146,
      'body': 'PRIVATE JOURNAL TEXT',
    }),
    'quizzes': record('quizzes', {
      'quiz_title': 'Wellbeing check-in',
      'score': 12,
      'maximum_score': 25,
      'interpretation': 'Your saved result summary',
    }),
    'notes': record('notes', {
      'body':
          'Try a short breathing exercise before bed and make a little time for rest.',
    }),
  };
  for (final dark in [false, true]) {
    for (final entry in examples.entries) {
      testWidgets(
        '${entry.key} card presents owner and summary without timestamps, dark=$dark',
        (tester) async {
          tester.view.physicalSize = const Size(390, 600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                fontFamily: 'Outfit',
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF0460D8),
                  brightness: dark ? Brightness.dark : Brightness.light,
                ),
              ),
              home: RepaintBoundary(
                key: surfaceCaptureKey,
                child: Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SharedRecordCard(record: entry.value),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Shared by Taylor'), findsOneWidget);
          expect(find.text('Cozy Health'), findsOneWidget);
          expect(find.textContaining('2026-10-17'), findsNothing);
          expect(find.textContaining('created_at'), findsNothing);
          expect(find.text('PRIVATE JOURNAL TEXT'), findsNothing);
          expect(tester.takeException(), isNull);
          await captureSurface(
            tester,
            'shared-${entry.key}-${dark ? 'dark' : 'light'}',
          );
        },
      );
    }
  }
  testWidgets(
    'unavailable card ignores former contents and long notes expand accessibly',
    (tester) async {
      final data = record('notes', {
        'body': List.filled(20, 'Time for rest.').join(' '),
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SharedRecordCard(record: data)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read more'));
      await tester.pump();
      expect(find.text('Show less'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SharedRecordCard(record: {...data, 'unavailable': true}),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Record unavailable'), findsOneWidget);
      expect(find.textContaining('Time for rest.'), findsNothing);
      expect(find.text('Read more'), findsNothing);
    },
  );
  testWidgets('large text and long names fit a narrow screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SharedRecordCard(
                record: {
                  ...examples['moods']!,
                  'owner': {'name': 'Alexandriaverylongname', 'initials': 'A'},
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
