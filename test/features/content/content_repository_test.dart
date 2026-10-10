import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/features/content/data/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<SavedArticle>(
    LocalDbService.savedArticleBoxName,
    SavedArticleAdapter(),
  );
  final repository = ContentRepository(usePlaceholderData: false);
  setUpAll(fixture.open);
  setUp(fixture.reset);
  tearDownAll(fixture.close);

  Map<String, dynamic> article(String id) => {
    'id': 'saved-$id',
    'article_id': id,
    'title': 'Article $id',
    'saved_at': '2026-10-10T12:00:00Z',
  };

  for (final shape in ['paginator', 'data list', 'raw list']) {
    test(
      'saved content reads $shape and caches articles by article ID',
      () async {
        final rows = [article('one'), article('two')];
        fixture.body = switch (shape) {
          'paginator' => {
            'data': {'data': rows, 'last_page': 1},
          },
          'data list' => {'data': rows},
          _ => rows,
        };
        final result = await repository.fetchSavedArticles();
        expect(result.map((row) => row.articleId), ['one', 'two']);
        expect(fixture.box.keys, ['one', 'two']);
        expect(fixture.requests.single.path, '/api/v1/content/saved');
      },
    );
  }

  test('saved content fetches every page', () async {
    // The same fixture page is returned twice; merging must remain idempotent.
    fixture.body = {
      'data': {
        'data': [article('one')],
        'last_page': 2,
      },
    };
    final result = await repository.fetchSavedArticles();
    expect(result, hasLength(1));
    expect(fixture.requests.map((uri) => uri.queryParameters['page']), [
      '1',
      '2',
    ]);
  });

  test('invalid response retains offline records', () async {
    await fixture.box.put('offline', SavedArticle.fromJson(article('offline')));
    fixture.body = {
      'data': {'unexpected': true},
    };
    final result = await repository.fetchSavedArticles();
    expect(result.single.articleId, 'offline');
  });
}
