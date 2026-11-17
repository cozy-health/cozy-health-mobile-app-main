import 'dart:io';

import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/mood_artwork.dart';
import 'package:cozy_health/features/mood_check_in/presentation/screens/mood_recording_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _MissingArtworkBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw StateError('Missing artwork');
}

void main() {
  const moods = ['angry', 'sad', 'good', 'upset', 'spectacular', 'happy'];

  test('six categories resolve to the exact existing Home assets', () {
    for (final mood in moods) {
      final expected = 'assets/png/home_reference_$mood.png';
      expect(MoodArtwork.assetFor(mood), expected);
      expect(MoodArtwork.assetFor('  ${mood.toUpperCase()}  '), expected);
      expect(File(expected).existsSync(), isTrue);
    }
    for (final mood in [
      'calm',
      'tired',
      'anxious',
      'okay',
      'low',
      'excited',
      '',
      'unknown',
    ]) {
      expect(MoodArtwork.assetFor(mood), isNull, reason: mood);
    }
  });

  testWidgets(
    'specific feelings retain the category character and visible label',
    (tester) async {
      for (final feeling in ['Resentful', 'Irritated']) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: RecordingSummary(
                mood: 'angry',
                feeling: feeling,
                intensity: 7,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final image = tester.widget<Image>(find.byType(Image));
        expect(
          (image.image as AssetImage).assetName,
          MoodArtwork.assetFor('angry'),
        );
        expect(image.excludeFromSemantics, isTrue);
        expect(find.text(feeling), findsOneWidget);
        expect(find.text('Strong · 4/5'), findsOneWidget);
      }
    },
  );

  testWidgets('legacy summary is label-only without an empty artwork slot', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: RecordingSummary(mood: 'calm', feeling: 'Calm', intensity: 5),
        ),
      ),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(MoodArtwork), findsNothing);
    expect(find.text('Calm'), findsOneWidget);
    final row = tester.widget<Row>(
      find.descendant(
        of: find.byType(RecordingSummary),
        matching: find.byType(Row),
      ),
    );
    expect(row.children, hasLength(1));
  });

  testWidgets(
    'failed asset loading never substitutes an emoji or another mood',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: _MissingArtworkBundle(),
            child: const Scaffold(
              body: Row(
                children: [
                  MoodArtwork(mood: 'angry', size: 36),
                  Text('Resentful'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Resentful'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(MoodArtwork)), Size.zero);
    },
  );

  test(
    'mood summaries cannot reintroduce emoji artwork outside feeling selection',
    () {
      final offenders = <String>[];
      final pattern = RegExp(
        r'\.emoji\b|MoodEntry\.moodEmojis|recording_emoji_',
      );
      for (final root in ['lib/features', 'lib/core/widgets']) {
        for (final file in Directory(
          root,
        ).listSync(recursive: true).whereType<File>()) {
          if (!file.path.endsWith('.dart')) continue;
          var source = file.readAsStringSync();
          if (file.path.endsWith('mood_feeling_screen.dart')) {
            final start = source.indexOf('  List<Widget> _feelingCards()');
            final end = source.indexOf('class MoodCheckInSuccessScreen');
            expect(start, greaterThanOrEqualTo(0));
            expect(end, greaterThan(start));
            // Existing feeling chips intentionally retain their own reference art.
            source = source.replaceRange(start, end, '');
          }
          if (pattern.hasMatch(source)) offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty);
    },
  );
}
