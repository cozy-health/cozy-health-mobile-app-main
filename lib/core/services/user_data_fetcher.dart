import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/app_notification.dart';
import '../models/chat_conversation.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';
import '../models/quiz_attempt.dart';
import '../models/safety_plan.dart';
import '../models/saved_article.dart';
import '../models/subscription_status.dart';
import '../models/user_profile.dart';
import 'local_db_service.dart';

class UserDataFetcher {
  static final _instance = UserDataFetcher._();
  factory UserDataFetcher() => _instance;
  UserDataFetcher._();

  final _api = ApiClient.instance;
  final _local = LocalDbService.instance;

  Future<void> fetchAll() async {
    final tasks = <Future<void>>[
      fetchMoods(),
      fetchJournals(),
      fetchConversations(),
      fetchNotifications(),
      fetchProfile(),
      fetchSafetyPlan(),
      fetchQuizAttempts(),
      fetchSavedArticles(),
      fetchSubscription(),
    ];
    await Future.wait(tasks, eagerError: false);
  }

  Future<void> fetchMoods() async {
    try {
      final entries = await _fetchPaginated<MoodEntry>(
        ApiConstants.moodEntries,
        (json) => MoodEntry.fromJson(json),
        debugLabel: 'moods',
        logRawResponse: true,
      );

      for (final entry in entries) {
        await _local.saveMoodEntry(entry);
      }

      debugPrint('Fetched ${entries.length} moods from backend');
    } catch (e) {
      debugPrint('Fetch moods failed: $e');
    }
  }

  Future<void> fetchJournals() async {
    await _fetchListDomain<JournalEntry>(
      endpoint: ApiConstants.journalEntries,
      fallbackEndpoint: ApiConstants.journals,
      debugLabel: 'journals',
      fromJson: (json) => JournalEntry.fromJson(json),
      save: _local.saveJournalEntry,
    );
  }

  Future<void> fetchConversations() async {
    await _fetchListDomain<ChatConversation>(
      endpoint: ApiConstants.conversations,
      debugLabel: 'conversations',
      fromJson: (json) => ChatConversation.fromJson(json),
      save: _local.saveChatConversation,
    );
  }

  Future<void> fetchNotifications() async {
    await _fetchListDomain<AppNotification>(
      endpoint: ApiConstants.notifications,
      debugLabel: 'notifications',
      fromJson: (json) => AppNotification.fromJson(json),
      save: _local.saveAppNotification,
    );
  }

  Future<void> fetchProfile() async {
    await _fetchSingleDomain<UserProfile>(
      endpoint: ApiConstants.me,
      debugLabel: 'profile',
      fromJson: (json) => UserProfile.fromJson(json),
      save: _local.saveUserProfile,
    );
  }

  Future<void> fetchSafetyPlan() async {
    await _fetchSingleDomain<SafetyPlan>(
      endpoint: ApiConstants.safetyPlan,
      debugLabel: 'safety plan',
      fromJson: (json) => SafetyPlan.fromJson(json),
      save: _local.saveSafetyPlan,
    );
  }

  Future<void> fetchQuizAttempts() async {
    await _fetchListDomain<QuizAttempt>(
      endpoint: ApiConstants.quizAttempts,
      fallbackEndpoint: ApiConstants.quizResults,
      debugLabel: 'quiz attempts',
      fromJson: (json) => QuizAttempt.fromJson(json),
      save: _local.saveQuizAttempt,
    );
  }

  Future<void> fetchSavedArticles() async {
    await _fetchListDomain<SavedArticle>(
      endpoint: ApiConstants.savedContent,
      debugLabel: 'saved articles',
      fromJson: (json) => SavedArticle.fromJson(json),
      save: _local.saveSavedArticle,
    );
  }

  Future<void> fetchSubscription() async {
    await _fetchSingleDomain<SubscriptionStatus>(
      endpoint: ApiConstants.subscription,
      debugLabel: 'subscription',
      fromJson: (json) => SubscriptionStatus.fromJson(json),
      save: _local.saveSubscriptionStatus,
    );
  }

  Future<void> _fetchListDomain<T>({
    required String endpoint,
    String? fallbackEndpoint,
    required String debugLabel,
    required T Function(Map<String, dynamic>) fromJson,
    required Future<void> Function(T) save,
  }) async {
    try {
      final items = await _fetchPaginated<T>(
        endpoint,
        fromJson,
        debugLabel: debugLabel,
      );
      for (final item in items) {
        await save(item);
      }
      debugPrint('Fetched ${items.length} $debugLabel from backend');
    } catch (e) {
      if (fallbackEndpoint == null) {
        debugPrint('Fetch $debugLabel skipped/failed: $e');
        return;
      }
      try {
        final items = await _fetchPaginated<T>(
          fallbackEndpoint,
          fromJson,
          debugLabel: debugLabel,
        );
        for (final item in items) {
          await save(item);
        }
        debugPrint('Fetched ${items.length} $debugLabel from backend');
      } catch (fallbackError) {
        debugPrint('Fetch $debugLabel skipped/failed: $fallbackError');
      }
    }
  }

  Future<void> _fetchSingleDomain<T>({
    required String endpoint,
    required String debugLabel,
    required T Function(Map<String, dynamic>) fromJson,
    required Future<void> Function(T) save,
  }) async {
    try {
      final response = await _api.get(endpoint);
      final item = _extractSingle(response.data);
      if (item == null) {
        debugPrint('Fetch $debugLabel skipped: empty response');
        return;
      }
      await save(fromJson(item));
      debugPrint('Fetched $debugLabel from backend');
    } catch (e) {
      debugPrint('Fetch $debugLabel skipped/failed: $e');
    }
  }

  Future<List<T>> _fetchPaginated<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    required String debugLabel,
    bool logRawResponse = false,
  }) async {
    var page = 1;
    var totalPages = 1;
    final items = <T>[];

    while (page <= totalPages) {
      final response = await _api.get(
        endpoint,
        queryParameters: {'page': page, 'per_page': 50},
      );
      if (logRawResponse) {
        debugPrint('MOODS API RESPONSE: ${response.data}');
      }

      final data = response.data is Map ? response.data['data'] : response.data;
      final list = _extractList(data);
      for (final item in list) {
        if (item is Map) {
          items.add(fromJson(Map<String, dynamic>.from(item)));
        }
      }

      totalPages = _lastPage(data) ?? _lastPage(response.data) ?? 1;
      debugPrint(
        'Fetched $debugLabel page $page/$totalPages: ${list.length} items',
      );
      page++;
    }

    return items;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final nested = data['data'] ?? data['items'] ?? data['results'];
      if (nested is List) return nested;
    }
    return const [];
  }

  Map<String, dynamic>? _extractSingle(dynamic data) {
    final payload = data is Map ? data['data'] ?? data : data;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return null;
  }

  int? _lastPage(dynamic data) {
    if (data is! Map) return null;
    final value = data['last_page'] ?? data['total_pages'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
