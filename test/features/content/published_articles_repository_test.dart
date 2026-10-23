import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/features/content/data/published_articles_repository.dart';

class ArticleApi extends Fake implements ApiClient {
  final paths = <String>[];
  bool fail = false;
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
    if (fail) throw StateError('Unavailable');
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
