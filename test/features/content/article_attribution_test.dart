import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/illustration_plate.dart';
import 'package:cozy_health/features/content/data/published_articles_repository.dart';
import 'package:cozy_health/features/content/presentation/screens/article_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';
import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<SavedArticle>(
    LocalDbService.savedArticleBoxName,
    SavedArticleAdapter(),
  );
  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    await installLocalTestFonts();
  });
  tearDown(resetLocalTestFonts);
  tearDownAll(fixture.close);

  testWidgets('article detail refreshes stale cached artwork in both themes', (
    tester,
  ) async {
    final article = PublishedArticle.fromJson({
      'id': 'published-support',
      'slug': 'asking-for-the-kind-of-support-you-want',
      'title': 'An edited published title',
      'body': 'The approved body stays unchanged.',
    });
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: ArticleDetailScreen(
            extra: {
              ...article.detail,
              'artwork': 'assets/png/recommended_wellbeing.png',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final plate = tester.widget<IllustrationPlate>(
        find.byType(IllustrationPlate),
      );
      expect(plate.asset, article.artwork);
      expect(find.text('The approved body stays unchanged.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'published article shows its body and attribution at large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ArticleDetailScreen(
              extra: const {
                'id': 'synthetic',
                'title': 'Published fixture',
                'publishedArticle': true,
                'body': 'Approved test body.',
                'license': 'Original test fixture',
                'source_url': 'https://example.test/source',
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('article-license')), findsOneWidget);
      expect(find.byKey(const ValueKey('article-source')), findsOneWidget);
      expect(find.text('Approved test body.'), findsOneWidget);
      expect(find.textContaining('Sarah Chen'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing published body never displays sample editorial text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const ArticleDetailScreen(
          extra: {
            'id': 'missing',
            'title': 'Missing content',
            'publishedArticle': true,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Article content is unavailable.'),
      findsOneWidget,
    );
    expect(find.text('What it feels like'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'saved article attribution survives Hive and JSON round trips',
    () async {
      final article = SavedArticle(
        id: 'saved',
        articleId: 'published',
        title: 'Fixture',
        excerpt: '',
        imageUrl: '',
        savedAt: DateTime.utc(2026),
        body: 'Saved body',
        license: 'Original test fixture',
        sourceUrl: 'https://example.test/source',
      );
      await fixture.box.put(article.id, article);
      await fixture.box.flush();
      await fixture.box.close();
      fixture.box = await EncryptedHive.openBox<SavedArticle>(
        LocalDbService.savedArticleBoxName,
      );
      final restored = SavedArticle.fromJson(
        fixture.box.get(article.id)!.toJson(),
      );
      expect(restored.license, article.license);
      expect(restored.sourceUrl, article.sourceUrl);
      expect(restored.body, article.body);
    },
  );
}
