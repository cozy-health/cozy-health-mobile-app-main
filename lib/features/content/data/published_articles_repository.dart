import '../../../core/api/api_client.dart';
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
      category = json['category']?.toString(),
      readMinutes = (json['read_time_minutes'] as num?)?.toInt();
  final String id, title, body, excerpt;
  final String? slug, category;
  final int? readMinutes;
  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'title': title,
    'body': body,
    'excerpt': excerpt,
    'category': category,
    'read_time_minutes': readMinutes,
  };
  Map<String, dynamic> get detail => {
    ...toJson(),
    'artwork': artwork,
    if (readMinutes != null) 'readTime': '$readMinutes min read',
    'publishedArticle': true,
  };
  String get artwork {
    final text = '$title ${category ?? ''}'.toLowerCase();
    final name = text.contains('gratitude')
        ? 'gratitude'
        : text.contains('burnout') ||
              text.contains('productiv') ||
              category == 'work'
        ? 'burnout'
        : text.contains('anxiety') ||
              text.contains('depression') ||
              text.contains('stress')
        ? 'anxiety'
        : 'wellbeing';
    return 'assets/png/recommended_$name.png';
  }
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
  Future<PublishedArticlePage> load({int page = 1}) async {
    final local = LocalDbService(), owner = LocalDbService().activeUserId;
    final box = await local.settingsBox();
    bool current() => owner == local.activeUserId;
    const key = 'published_articles_v1';
    try {
      if (networkOffline.value == true) throw StateError('Offline');
      final raw = responseMap(
        await _api.get(
          '/content/articles',
          queryParameters: {'page': page, 'per_page': 20},
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
      if (page == 1 && current()) {
        await box.put(key, {'data': rows.map((a) => a.toJson()).toList()});
      }
      if (!current()) throw StateError('Account changed');
      return PublishedArticlePage(rows, page, last);
    } catch (_) {
      if (!current()) rethrow;
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
