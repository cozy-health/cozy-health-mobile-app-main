import '../../../core/data/demo_mode.dart';
import '../../../core/data/placeholder_data.dart';
import 'package:flutter/foundation.dart';

import '../../../core/models/saved_article.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/services/user_data_merge.dart';

class ContentRepository {
  ContentRepository({bool? usePlaceholderData})
    : _placeholderOverride = usePlaceholderData;
  final bool? _placeholderOverride;
  bool get usePlaceholderData =>
      _placeholderOverride ?? DemoMode.instance.enabled;
  List<Map<String, String>> get catalog => usePlaceholderData
      ? PlaceholderData.articles()
      : const [
          {
            'id': 'voice-in-your-head',
            'title': 'The Voice in Your Head',
            'category': 'Anxiety',
            'readTime': '5 min read',
          },
        ];
  final LocalDbService _local = LocalDbService();

  Future<List<SavedArticle>> fetchSavedArticles() async {
    if (usePlaceholderData) return List.of(DemoMode.instance.savedArticles);
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    bool active() =>
        scope == _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      var page = 1;
      var lastPage = 1;
      do {
        final response = await ApiClient.instance.get(
          '/content/saved',
          queryParameters: {'page': page, 'per_page': 100},
        );
        if (!active()) return const [];
        dynamic payload = response.data;
        if (payload is Map) payload = payload['data'];
        if (payload is Map) {
          final last = payload['last_page'];
          if (last is! int || last < page) {
            throw const FormatException('Invalid saved-content pagination');
          }
          lastPage = last;
          payload = payload['data'];
        }
        if (payload is! List) {
          throw const FormatException('Invalid saved-content response');
        }
        for (final raw in payload) {
          if (raw is! Map) {
            throw const FormatException('Invalid saved article');
          }
          await UserDataMerge().apply(
            'saved_article',
            Map<String, dynamic>.from(raw),
            isActive: active,
          );
          if (!active()) return const [];
        }
        page++;
      } while (page <= lastPage);
      return _local.getAllSavedArticles();
    } on ApiAuthException {
      rethrow;
    } catch (_) {
      if (!active()) return const [];
      return _local.getAllSavedArticles();
    }
  }

  Stream<List<SavedArticle>> watchSavedArticles() {
    return DemoMode.instance.selectStream(
      useDemo: () => usePlaceholderData,
      real: _local.watchSavedArticles,
      demo: () => DemoMode.instance.savedArticles,
    );
  }

  Future<void> saveArticle(String articleId) async {
    if (usePlaceholderData) {
      if (!DemoMode.instance.savedArticles.any(
        (a) => a.articleId == articleId,
      )) {
        await toggleSave({'id': articleId});
      }
      return;
    }
    try {
      await ApiClient.instance.post('/content/articles/$articleId/save');
      fetchSavedArticles();
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Future<void> unsaveArticle(String articleId) async {
    if (usePlaceholderData) {
      DemoMode.instance.savedArticles.removeWhere(
        (a) => a.articleId == articleId,
      );
      DemoMode.instance.changed();
      return;
    }
    try {
      await ApiClient.instance.delete('/content/articles/$articleId/save');
      fetchSavedArticles();
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Stream<bool> isSaved(String articleId) {
    return watchSavedArticles().map(
      (articles) => articles.any((a) => a.articleId == articleId),
    );
  }

  Future<void> toggleSave(Map<String, dynamic> articleData) async {
    final articleId = articleData['id'] as String;
    final savedArticles = usePlaceholderData
        ? DemoMode.instance.savedArticles
        : _local.getAllSavedArticles();
    final isCurrentlySaved = savedArticles.any((a) => a.articleId == articleId);
    if (usePlaceholderData) {
      if (isCurrentlySaved) {
        savedArticles.removeWhere((row) => row.articleId == articleId);
      } else {
        savedArticles.add(
          SavedArticle(
            id: 'demo-saved-$articleId',
            articleId: articleId,
            title: articleData['title'] as String? ?? '',
            excerpt: articleData['excerpt'] as String? ?? '',
            imageUrl: articleData['image_url'] as String? ?? '',
            savedAt: DateTime.now(),
          ),
        );
      }
      DemoMode.instance.changed();
      return;
    }
    if (isCurrentlySaved) {
      await _local.deleteSavedArticle(articleId);
      await _local.enqueueSync(
        type: 'saved_article',
        action: 'delete',
        recordId: articleId,
        payload: null,
      );
    } else {
      final article = SavedArticle(
        id: 'saved_$articleId',
        articleId: articleId,
        articleSlug: articleData['slug'] as String?,
        title: articleData['title'] as String? ?? '',
        category: articleData['category'] as String?,
        readTimeMinutes: articleData['read_time_minutes'] as int?,
        excerpt: articleData['excerpt'] as String? ?? '',
        imageUrl: articleData['image_url'] as String? ?? '',
        savedAt: DateTime.now().toUtc(),
      );
      await _local.saveSavedArticle(article);
      await _local.enqueueSync(
        type: 'saved_article',
        action: 'upsert',
        recordId: article.articleId,
        payload: article.toJson(),
      );
    }
    _local.processSyncQueue();
  }
}
