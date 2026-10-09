import 'package:flutter/foundation.dart';

import '../../../core/models/saved_article.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class ContentRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<SavedArticle>> fetchSavedArticles() async {
    try {
      final response = await ApiClient.instance.get('/content/saved');
      final items = (response.data['data'] as List)
          .map((json) => SavedArticle.fromJson(json))
          .toList();
      for (final item in items) {
        await _local.saveSavedArticle(item);
      }
      return items;
    } catch (e) {
      return _local.getAllSavedArticles();
    }
  }

  Stream<List<SavedArticle>> watchSavedArticles() {
    return _local.watchSavedArticles();
  }

  Future<void> saveArticle(String articleId) async {
    try {
      await ApiClient.instance.post('/content/articles/$articleId/save');
      fetchSavedArticles();
    } catch (_) {
      debugPrint('Caught error: details withheld.');
    }
  }

  Future<void> unsaveArticle(String articleId) async {
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
    final savedArticles = _local.getAllSavedArticles();
    final isCurrentlySaved = savedArticles.any((a) => a.articleId == articleId);
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
