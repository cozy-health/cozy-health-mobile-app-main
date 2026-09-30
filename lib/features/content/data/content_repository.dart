import 'package:flutter/foundation.dart';
import '../../../core/models/saved_article.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class ContentRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<SavedArticle>> fetchSavedArticles() async {
    try {
      final response = await ApiClient.instance.get('/content/saved');
      final items = (response.data['data'] as List).map((json) => SavedArticle.fromJson(json)).toList();
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
    } catch(e) {}
  }
  
  Future<void> unsaveArticle(String articleId) async {
    try {
      await ApiClient.instance.delete('/content/articles/$articleId/save');
      fetchSavedArticles();
    } catch(e) {}
  }
}