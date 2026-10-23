import 'package:cozy_health/features/content/data/published_articles_repository.dart';
import 'package:cozy_health/features/content/presentation/screens/published_article_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BrowserRepository extends PublishedArticlesRepository {
  bool fail = false;
  final calls = <({int page, String query, String? category})>[];
  @override
  Future<List<Map<String, String>>> categories() async => [
    {'slug': 'sleep', 'name': 'Sleep'},
  ];
  @override
  Future<PublishedArticlePage> browse({
    int page = 1,
    String query = '',
    String? category,
  }) async {
    calls.add((page: page, query: query, category: category));
    if (fail) throw StateError('Unavailable');
    return PublishedArticlePage(
      [
        PublishedArticle.fromJson({
          'id': '$query-$page',
          'title': 'Published ${query.isEmpty ? 'article' : query} $page',
          'excerpt': 'Server excerpt',
        }),
      ],
      page,
      2,
    );
  }
}

void main() {
  testWidgets('published search, category and pagination use one catalogue', (
    tester,
  ) async {
    final repository = BrowserRepository();
    await tester.pumpWidget(
      MaterialApp(home: PublishedArticleBrowser(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Published article 1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'sleep');
    await tester.tap(find.byKey(const ValueKey('article-search')));
    await tester.pumpAndSettle();
    expect(find.text('Published article 1'), findsNothing);
    expect(find.text('Published sleep 1'), findsOneWidget);
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();
    expect(repository.calls.last.category, 'sleep');
    await tester.ensureVisible(find.text('Load more articles'));
    await tester.tap(find.text('Load more articles'));
    await tester.pumpAndSettle();
    expect(find.text('Published sleep 1'), findsOneWidget);
    expect(find.text('Published sleep 2'), findsOneWidget);
    expect(repository.calls.last.page, 2);
  });
  testWidgets('catalogue failure offers retry instead of static articles', (
    tester,
  ) async {
    final repository = BrowserRepository()..fail = true;
    await tester.pumpWidget(
      MaterialApp(home: PublishedArticleBrowser(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load published articles. Please retry.'),
      findsOneWidget,
    );
    expect(find.text('The Voice in Your Head'), findsNothing);
    repository.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Published article 1'), findsOneWidget);
  });
}
