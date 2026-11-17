import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/theme/wellness_tokens.dart';
import 'package:cozy_health/core/widgets/illustration_plate.dart';
import 'package:cozy_health/core/artwork/content_artwork.dart';
import 'package:cozy_health/features/content/data/published_articles_repository.dart';
import 'package:cozy_health/features/content/presentation/widgets/recommended_article_grid.dart';
import 'package:cozy_health/features/quiz/presentation/screen/quiz_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';

const articleSlugs = [
  'a-small-start-with-journaling',
  'putting-a-mood-check-in-into-context',
  'asking-for-the-kind-of-support-you-want',
];
const assessmentArtwork = {
  'wellbeing-check': 'assets/png/home_quiz_brain.png',
  'cozy-coping-and-resilience': 'assets/png/copingandresilence.png',
  'cozy-emotional-well-being': 'assets/png/emotional_wellbeing.png',
  'cozy-low-mood': 'assets/png/depression.png',
  'cozy-social-and-relationship-well-being':
      'assets/png/social_relationship.png',
  'cozy-stress-and-anxiety': 'assets/png/stressandanxiety.png',
};

Map<String, dynamic> assessment(String slug) => {
  'slug': slug,
  'title': 'Published $slug',
  'questions': <Map<String, dynamic>>[],
  'definition_version': 'published-version',
};

Future<void> captureAssessment(
  WidgetTester tester,
  String name,
  String asset,
) async {
  if (!const bool.fromEnvironment('SURFACE_SCREENSHOTS')) return;
  await tester.runAsync(
    () => precacheImage(
      AssetImage(asset),
      tester.element(find.byType(Image).first),
    ),
  );
  await tester.pumpAndSettle();
  await captureSurface(tester, name);
}

void main() {
  setUp(installLocalTestFonts);
  tearDown(resetLocalTestFonts);

  test(
    'published articles have distinct stable artwork after cache round trip',
    () {
      final articles = [
        for (final slug in articleSlugs)
          PublishedArticle.fromJson({
            'id': slug,
            'slug': slug,
            'title': 'Edited title',
          }),
      ];
      expect(articles.map((a) => a.artwork).toSet(), hasLength(3));
      for (final article in articles) {
        expect(
          PublishedArticle.fromJson(article.toJson()).artwork,
          article.artwork,
        );
        expect(article.detail['artwork'], article.artwork);
      }
    },
  );

  testWidgets('each published assessment uses its own existing illustration', (
    tester,
  ) async {
    for (final entry in assessmentArtwork.entries) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (_, child) =>
              RepaintBoundary(key: surfaceCaptureKey, child: child!),
          home: QuizDetailScreen(extra: {'definition': assessment(entry.key)}),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(find.byType(Image).first);
      expect(
        (image.image as AssetImage).assetName,
        entry.value,
        reason: entry.key,
      );
      await captureAssessment(
        tester,
        'e06-assessment-${entry.key}',
        entry.value,
      );
    }
  });

  testWidgets('dark assessment artwork has a legible illustration plate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (_, child) =>
            RepaintBoundary(key: surfaceCaptureKey, child: child!),
        home: QuizDetailScreen(
          extra: {'definition': assessment('cozy-stress-and-anxiety')},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final plate = find.ancestor(
      of: find.byType(Image).first,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color ==
                const WellnessTokens().artworkSurface,
      ),
    );
    expect(plate, findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureAssessment(
      tester,
      'e06-assessment-dark',
      'assets/png/stressandanxiety.png',
    );
  });

  test(
    'unknown content has a neutral fallback and clinical slugs stay supported',
    () {
      expect(
        ContentArtwork.assessment('unknown'),
        'assets/png/home_quiz_brain.png',
      );
      expect(
        ContentArtwork.assessment('gad-7'),
        'assets/png/stressandanxiety.png',
      );
      expect(ContentArtwork.assessment('phq-9'), 'assets/png/depression.png');
      expect(ContentArtwork.article(), 'assets/png/recommended_wellbeing.png');
    },
  );

  testWidgets(
    'article cards retain contrast and taps across themes at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final articles = [
        for (final slug in articleSlugs)
          PublishedArticle.fromJson({
            'id': slug,
            'slug': slug,
            'title': 'A thoughtful published article with a longer title',
          }),
      ];
      for (final base in [AppTheme.light, AppTheme.dark]) {
        for (final accent in [
          AppColors.primary,
          AppColors.success,
          AppColors.warmOrange,
          AppColors.warning,
        ]) {
          for (final highContrast in [false, true]) {
            var theme = AppTheme.withAccent(base, accent);
            if (highContrast) theme = AppTheme.highContrast(theme);
            String? opened;
            late BuildContext cardContext;
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                builder: (_, child) =>
                    RepaintBoundary(key: surfaceCaptureKey, child: child!),
                home: MediaQuery(
                  data: MediaQueryData(
                    textScaler: const TextScaler.linear(2),
                    highContrast: highContrast,
                  ),
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: Builder(
                        builder: (context) {
                          cardContext = context;
                          return ArticleRecommendationGrid(
                            articles: articles,
                            onOpen: (article) => opened = article.id,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.byType(IllustrationPlate), findsNWidgets(3));
            expect(tester.takeException(), isNull);
            await captureSurface(
              tester,
              'e06-articles-${base.brightness.name}-${accent.toARGB32()}-$highContrast',
            );
            final background = cardContext.cozyColors.wellness.accentPanel(
              theme.colorScheme,
            );
            final foreground = theme.colorScheme.onSurface;
            final light = foreground.computeLuminance(),
                dark = background.computeLuminance();
            final ratio = light > dark
                ? (light + .05) / (dark + .05)
                : (dark + .05) / (light + .05);
            expect(ratio, greaterThanOrEqualTo(4.5));
            await tester.tap(
              find.byKey(ValueKey('article-${articleSlugs.first}')),
            );
            await tester.pump();
            expect(opened, articleSlugs.first);
          }
        }
      }
    },
  );
}
