import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../models/subscription_status.dart';
import 'local_db_service.dart';
import 'user_data_merge.dart';

/// Streams render Hive immediately; refreshes only merge into the active account.
class UserDataFetcher {
  final _api = ApiClient.instance;
  final _local = LocalDbService();
  final _merge = UserDataMerge();
  Future<void> fetchAll() async => Future.wait([
    fetchMoods(),
    fetchJournals(),
    fetchConversations(),
    fetchNotifications(),
    fetchProfile(),
    fetchSafetyPlan(),
    fetchQuizAttempts(),
    fetchSavedArticles(),
    fetchSubscription(),
  ]);
  Future<void> fetchMoods() => _list('/mood-entries', 'mood_entry');
  Future<void> fetchJournals() => _list('/journal-entries', 'journal_entry');
  Future<void> fetchConversations() =>
      _list('/conversations', 'chat_conversation');
  Future<void> fetchNotifications() =>
      _list('/notifications', 'app_notification');
  Future<void> fetchQuizAttempts() => _list('/quiz-attempts', 'quiz_attempt');
  Future<void> fetchSavedArticles() =>
      _list('/saved-articles', 'saved_article');
  Future<void> fetchProfile() => _single('/user/profile', 'user_profile');
  Future<void> fetchSafetyPlan() => _single('/safety-plan', 'safety_plan');
  Future<void> fetchSubscription() async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await _api.get('/subscription');
      final data = response.data is Map
          ? response.data['data'] ?? response.data
          : null;
      if (data is Map &&
          scope == _local.boxName(LocalDbService.userSettingsBoxName)) {
        await _local.saveSubscriptionStatus(
          SubscriptionStatus.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    } catch (_) {
      debugPrint('Subscription refresh unavailable; retaining cache.');
    }
  }

  Future<void> _single(String endpoint, String type) async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await _api.get(endpoint);
      final data = response.data is Map
          ? response.data['data'] ?? response.data
          : null;
      if (data is Map &&
          scope == _local.boxName(LocalDbService.userSettingsBoxName)) {
        await _merge.apply(
          type,
          Map<String, dynamic>.from(data),
          isActive: () =>
              scope == _local.boxName(LocalDbService.userSettingsBoxName),
        );
      }
    } catch (_) {
      debugPrint('$type refresh unavailable; retaining cache.');
    }
  }

  Future<void> _list(String endpoint, String type) async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      var page = 1;
      var lastPage = 1;
      do {
        final response = await _api.get(
          endpoint,
          queryParameters: {'page': page, 'per_page': 50},
        );
        if (scope != _local.boxName(LocalDbService.userSettingsBoxName)) return;
        final data = response.data is Map
            ? response.data['data'] ?? response.data
            : response.data;
        final rows = data is Map ? data['data'] : data;
        if (rows is! List) throw const FormatException('Invalid collection');
        final last = data is Map ? data['last_page'] : null;
        lastPage = last is num ? last.toInt() : 1;
        if (lastPage < page || lastPage > 1000) {
          throw const FormatException('Invalid pagination');
        }
        for (final row in rows) {
          if (row is! Map) throw const FormatException('Invalid record');
          await _merge.apply(
            type,
            Map<String, dynamic>.from(row),
            isActive: () =>
                scope == _local.boxName(LocalDbService.userSettingsBoxName),
          );
        }
        page++;
      } while (page <= lastPage);
    } catch (_) {
      debugPrint('$type refresh unavailable; retaining cache.');
    }
  }
}
