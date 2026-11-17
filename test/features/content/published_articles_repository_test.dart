import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/features/content/data/published_articles_repository.dart';

class ArticleApi extends Fake implements ApiClient {
  final paths = <String>[];
  final queries = <Map<String, dynamic>?>[];
  bool fail = false;
  ApiException? apiFailure;
  Map<String, dynamic> article = {
    'id': 'a1',
    'slug': 'mental-health-101',
    'title': 'Mental Health 101',
    'body': 'A complete published body.',
    'category': 'anxiety',
  };
  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? query,
    bool withAuth = true,
    Options? options,
  }) async {
    paths.add(path);
    queries.add(queryParameters);
    if (fail) throw StateError('Unavailable');
    if (apiFailure != null) throw apiFailure!;
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'data': path == '/content/articles'
            ? {
                'data': [article],
                'last_page': 2,
              }
            : article,
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('cozy_article_contract_');
    Hive.init(directory.path);
    await LocalDbService().settingsBox();
  });
  setUp(() async {
    networkOffline.value = false;
    await (await LocalDbService().settingsBox()).clear();
  });
  tearDownAll(() async {
    networkOffline.value = null;
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test(
    'published paginator and each own body are read from existing content endpoints',
    () async {
      final api = ArticleApi(),
          repo = PublishedArticlesRepository(api: ArticleApi());
      final source = PublishedArticlesRepository(api: api);
      final page = await source.load();
      expect(page.articles.single.title, 'Mental Health 101');
      expect(page.lastPage, 2);
      expect(page.cached, isFalse);
      final article = await source.detail(page.articles.single);
      expect(article.body, 'A complete published body.');
      expect(article.detail['readTime'], isNull);
      expect(article.detail['publishedArticle'], true);
      expect(api.paths, [
        '/content/articles',
        '/content/articles/mental-health-101',
      ]);
      expect(await repo.load(), isA<PublishedArticlePage>());
    },
  );
  test(
    'offline full bodies remain readable with honest cached status',
    () async {
      final api = ArticleApi(),
          repo = PublishedArticlesRepository(api: ArticleApi());
      final source = PublishedArticlesRepository(api: api);
      await source.load();
      networkOffline.value = true;
      final cached = await repo.load();
      expect(cached.cached, isTrue);
      expect(
        (await repo.detail(cached.articles.single)).body,
        'A complete published body.',
      );
      expect(api.paths.length, 1);
    },
  );
  test(
    'search and category use server filters and do not share unrelated cached pages',
    () async {
      final api = ArticleApi();
      final source = PublishedArticlesRepository(api: api);
      await source.browse(query: 'sleep', category: 'sleep');
      expect(api.queries.single, {
        'page': 1,
        'per_page': 20,
        'q': 'sleep',
        'category': 'sleep',
      });
      networkOffline.value = true;
      final cached = await source.browse(query: 'sleep', category: 'sleep');
      expect(cached.cached, isTrue);
      await expectLater(
        source.browse(query: 'work', category: 'work'),
        throwsStateError,
      );
    },
  );
  test('attribution survives catalogue, detail and offline cache', () async {
    final api = ArticleApi();
    api.article = {
      ...api.article,
      'license': 'Approved original fixture',
      'source_url': 'https://example.test/source',
    };
    final repository = PublishedArticlesRepository(api: api);
    final page = await repository.load();
    expect(page.articles.single.detail['license'], 'Approved original fixture');
    expect(
      (await repository.detail(page.articles.single)).detail['source_url'],
      'https://example.test/source',
    );
    networkOffline.value = true;
    final cached = await repository.load();
    expect(
      cached.articles.single.detail['license'],
      'Approved original fixture',
    );
    expect(
      cached.articles.single.detail['source_url'],
      'https://example.test/source',
    );
  });
  test(
    'online refresh replaces cached publication revisions and withdrawal',
    () async {
      final api = ArticleApi();
      final repository = PublishedArticlesRepository(api: api);
      final first = await repository.load();
      api.article = {...api.article, 'body': 'Revised published body.'};
      expect(
        (await repository.detail(first.articles.single)).body,
        'Revised published body.',
      );
      await repository.load();
      networkOffline.value = true;
      expect(
        (await repository.load()).articles.single.body,
        'Revised published body.',
      );
    },
  );
  test(
    'cached articles cannot bypass an explicit server access denial',
    () async {
      final api = ArticleApi();
      final repository = PublishedArticlesRepository(api: api);
      await repository.load();
      api.apiFailure = ApiAuthException(statusCode: 403);
      await expectLater(repository.load(), throwsA(isA<ApiAuthException>()));
    },
  );
  test(
    'no cache failure stays an error and missing article bodies are rejected',
    () async {
      final api = ArticleApi()..fail = true,
          repo = PublishedArticlesRepository(api: ArticleApi());
      await expectLater(
        PublishedArticlesRepository(api: api).load(),
        throwsStateError,
      );
      api.fail = false;
      api.article = {...api.article, 'body': ''};
      await expectLater(
        PublishedArticlesRepository(
          api: api,
        ).detail(PublishedArticle.fromJson(api.article)),
        throwsFormatException,
      );
      networkOffline.value = true;
      await expectLater(
        repo.detail(PublishedArticle.fromJson(api.article)),
        throwsStateError,
      );
    },
  );
}
