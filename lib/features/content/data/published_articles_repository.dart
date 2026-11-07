import '../../../core/api/api_client.dart';
import '../../../core/artwork/content_artwork.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/api/response_data.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/network_status.dart';

class PublishedArticle {
  PublishedArticle.fromJson(Map<String, dynamic> json)
    : id = json['id'].toString(),
      slug = json['slug']?.toString(),
      title = json['title']?.toString() ?? '',
      body = json['body']?.toString() ?? '',
      excerpt = json['excerpt']?.toString() ?? '',
      license = json['license']?.toString(),
      sourceUrl = json['source_url']?.toString(),
      category = json['category']?.toString(),
      readMinutes = (json['read_time_minutes'] as num?)?.toInt();
  final String id, title, body, excerpt;
  final String? slug, category, license, sourceUrl;
  final int? readMinutes;
  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'body': body,
    'excerpt': excerpt,
    'license': license,
    'source_url': sourceUrl,
    'category': category,
    'read_time_minutes': readMinutes,
  };
  Map<String, dynamic> get detail => {
    ...toJson(),
    'artwork': artwork,
    if (readMinutes != null) 'readTime': '$readMinutes min read',
    'publishedArticle': true,
  };
  String get artwork =>
      ContentArtwork.article(slug: slug, title: title, category: category);
}

class PublishedArticlePage {
  const PublishedArticlePage(
    this.articles,
    this.page,
    this.lastPage, {
    this.cached = false,
  });
  final List<PublishedArticle> articles;
  final int page, lastPage;
  final bool cached;
}

class PublishedArticlesRepository {
  PublishedArticlesRepository({ApiClient? api})
    : _api = api ?? ApiClient.instance;
  final ApiClient _api;
  Future<PublishedArticlePage> load({int page = 1}) => browse(page: page);

  Future<List<Map<String, String>>> categories() async {
    final response = responseMap(await _api.get('/content/categories'));
    final data = response['data'];
    if (data is! List) throw const FormatException('Invalid categories');
    return data.map((row) {
      if (row is! Map || row['slug'] is! String || row['name'] is! String) {
        throw const FormatException('Invalid category');
      }
      return {'slug': row['slug'] as String, 'name': row['name'] as String};
    }).toList();
  }

  Future<PublishedArticlePage> browse({
    int page = 1,
    String query = '',
    String? category,
  }) async {
    final local = LocalDbService(), owner = LocalDbService().activeUserId;
    final box = await local.settingsBox();
    bool current() => owner == local.activeUserId;
    final key =
        'published_articles_v2:${Uri.encodeComponent(query)}:${category ?? ''}';
    try {
      if (networkOffline.value == true) throw StateError('Offline');
      final raw = responseMap(
        await _api.get(
          '/content/articles',
          queryParameters: {
            'page': page,
            'per_page': 20,
            if (query.trim().isNotEmpty) 'q': query.trim(),
            if (category != null && category.isNotEmpty) 'category': category,
          },
        ),
      );
      if (!current()) throw StateError('Account changed');
      final payload = raw['data'];
      if (payload is! Map || payload['data'] is! List) {
        throw const FormatException('Invalid article page');
      }
      final rows = (payload['data'] as List)
          .map(
            (row) => PublishedArticle.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .where((a) => a.id != 'null' && a.title.trim().isNotEmpty)
          .toList();
      final last = (payload['last_page'] as num?)?.toInt() ?? page;
      if (last < page || last > 1000) {
        throw const FormatException('Invalid article pagination');
      }
      if (page == 1 && current()) {
        await box.put(key, {'data': rows.map((a) => a.toJson()).toList()});
      }
      if (!current()) throw StateError('Account changed');
      return PublishedArticlePage(rows, page, last);
    } catch (error) {
      if (!current()) rethrow;
      if (error is ApiAuthException ||
          (error is ApiException && error.statusCode != null)) {
        rethrow;
      }
      final cached = box.get(key);
      if (page == 1 && cached is Map && cached['data'] is List) {
        return PublishedArticlePage(
          (cached['data'] as List)
              .map(
                (e) => PublishedArticle.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
          1,
          1,
          cached: true,
        );
      }
      rethrow;
    }
  }

  Future<PublishedArticle> detail(PublishedArticle article) async {
    if (networkOffline.value == true) {
      if (article.body.trim().isEmpty) {
        throw StateError('Reconnect to read this article');
      }
      return article;
    }
    final owner = LocalDbService().activeUserId;
    final response = responseMap(
      await _api.get(
        '/content/articles/${Uri.encodeComponent(article.slug ?? article.id)}',
      ),
    );
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed');
    }
    final data = response['data'];
    if (data is! Map) throw const FormatException('Invalid article');
    final full = PublishedArticle.fromJson(Map<String, dynamic>.from(data));
    if (full.body.trim().isEmpty) {
      throw const FormatException('Article body is unavailable');
    }
    return full;
  }
}
