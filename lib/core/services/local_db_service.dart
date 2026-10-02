import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/sync_item.dart';
import 'package:uuid/uuid.dart';

import '../models/mood_entry.dart';
import '../models/journal_entry.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/safety_plan.dart';
import '../models/user_profile.dart';
import '../models/quiz_attempt.dart';
import '../models/saved_article.dart';
import '../models/app_notification.dart';
import '../models/subscription_status.dart';

class LocalDbService {
  // Singleton pattern
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();
  static LocalDbService get instance => _instance;
  bool _isProcessingSyncQueue = false;

  static const String moodBoxName = 'moods';
  static const String journalBoxName = 'journals';
  static const String chatMessageBoxName = 'chat_messages';
  static const String chatConversationBoxName = 'chat_conversations';
  static const String safetyPlanBoxName = 'safety_plan';
  static const String userProfileBoxName = 'user_profile';
  static const String quizAttemptBoxName = 'quiz_attempts';
  static const String savedArticleBoxName = 'saved_articles';
  static const String appNotificationBoxName = 'app_notifications';
  static const String subscriptionStatusBoxName = 'subscription_status';
  static const String syncQueueBoxName = 'sync_queue';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(MoodEntryAdapter());
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(ChatMessageAdapter());
    Hive.registerAdapter(ChatConversationAdapter());
    Hive.registerAdapter(SafetyPlanAdapter());
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(QuizAttemptAdapter());
    Hive.registerAdapter(SavedArticleAdapter());
    Hive.registerAdapter(AppNotificationAdapter());
    Hive.registerAdapter(SubscriptionStatusAdapter());

    // Open Boxes
    await Hive.openBox<MoodEntry>(moodBoxName);
    await Hive.openBox<JournalEntry>(journalBoxName);
    await Hive.openBox<ChatMessage>(chatMessageBoxName);
    await Hive.openBox<ChatConversation>(chatConversationBoxName);
    await Hive.openBox<SafetyPlan>(safetyPlanBoxName);
    await Hive.openBox<UserProfile>(userProfileBoxName);
    await Hive.openBox<QuizAttempt>(quizAttemptBoxName);
    await Hive.openBox<SavedArticle>(savedArticleBoxName);
    await Hive.openBox<AppNotification>(appNotificationBoxName);
    await Hive.openBox<SubscriptionStatus>(subscriptionStatusBoxName);
    await Hive.openBox<String>(syncQueueBoxName);
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        processSyncQueue();
      }
    });
    Timer.periodic(const Duration(minutes: 5), (_) {
      processSyncQueue();
    });
    Future.microtask(() => processSyncQueue());
  }

  // --- Moods ---
  Box<MoodEntry> get moodBox => Hive.box<MoodEntry>(moodBoxName);

  Future<void> saveMoodEntry(MoodEntry entry) async {
    await moodBox.put(entry.id, entry);
  }

  List<MoodEntry> getAllMoodEntries() {
    return moodBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<MoodEntry>> watchMoodEntries() async* {
    yield getAllMoodEntries();
    yield* moodBox.watch().map((_) => getAllMoodEntries());
  }

  // --- Journals ---
  Box<JournalEntry> get journalBox => Hive.box<JournalEntry>(journalBoxName);

  Future<void> saveJournalEntry(JournalEntry entry) async {
    await journalBox.put(entry.id, entry);
  }

  List<JournalEntry> getAllJournalEntries() {
    return journalBox.values.where((entry) => !entry.isDraft).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<JournalEntry>> watchJournalEntries() async* {
    yield getAllJournalEntries();
    yield* journalBox.watch().map((_) => getAllJournalEntries());
  }

  Future<void> deleteJournalEntry(String id) async {
    await journalBox.delete(id);
  }

  Future<void> saveJournalDraft(JournalEntry entry) async {
    await journalBox.put(entry.id, entry);
  }

  JournalEntry? getJournalDraft(String id) {
    final entry = journalBox.get(id);
    return entry != null && entry.isDraft ? entry : null;
  }

  Future<void> deleteJournalDraft(String id) async {
    final entry = journalBox.get(id);
    if (entry != null && entry.isDraft) {
      await journalBox.delete(id);
    }
  }

  // --- Chat ---
  Box<ChatMessage> get chatMessageBox =>
      Hive.box<ChatMessage>(chatMessageBoxName);
  Box<ChatConversation> get chatConversationBox =>
      Hive.box<ChatConversation>(chatConversationBoxName);

  Future<void> saveChatMessage(ChatMessage message) async {
    await chatMessageBox.put(message.id, message);
  }

  Future<void> saveChatConversation(ChatConversation conversation) async {
    await chatConversationBox.put(conversation.id, conversation);
  }

  Stream<List<ChatConversation>> watchConversations() async* {
    yield getAllConversations();
    yield* chatConversationBox.watch().map((_) => getAllConversations());
  }

  Stream<List<ChatConversation>> watchChatConversations() =>
      watchConversations();

  List<ChatConversation> getAllConversations() {
    return chatConversationBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<ChatConversation> getAllChatConversations() => getAllConversations();

  Future<void> deleteChatConversation(String id) async {
    await chatConversationBox.delete(id);
    // Also delete messages
    final messages = getMessagesForConversation(id);
    for (var m in messages) {
      await chatMessageBox.delete(m.id);
    }
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) async* {
    yield getMessagesForConversation(conversationId);
    yield* chatMessageBox.watch().map(
      (_) => getMessagesForConversation(conversationId),
    );
  }

  Stream<List<ChatMessage>> watchChatMessages(String conversationId) =>
      watchMessages(conversationId);

  List<ChatMessage> getMessagesForConversation(String conversationId) {
    return chatMessageBox.values
        .where((m) => m.conversationId == conversationId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  ChatMessage? getChatMessage(String id) {
    return chatMessageBox.get(id);
  }

  // --- Safety Plan ---
  Box<SafetyPlan> get safetyPlanBox => Hive.box<SafetyPlan>(safetyPlanBoxName);

  Future<void> saveSafetyPlan(SafetyPlan plan) async {
    await safetyPlanBox.put(plan.id, plan);
  }

  Stream<SafetyPlan?> watchSafetyPlan() {
    return safetyPlanBox.watch().map((_) => safetyPlanBox.values.firstOrNull);
  }

  SafetyPlan? getSafetyPlan() {
    return safetyPlanBox.values.firstOrNull;
  }

  Future<void> clearSafetyPlan() async {
    await safetyPlanBox.clear();
  }

  // --- User Profile ---
  Box<UserProfile> get userProfileBox =>
      Hive.box<UserProfile>(userProfileBoxName);

  bool get isUserProfileBoxOpen => Hive.isBoxOpen(userProfileBoxName);

  Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put(profile.id, profile);
  }

  Stream<UserProfile?> watchUserProfile() async* {
    UserProfile? readFresh() {
      final key = userProfileBox.keys.firstOrNull;
      if (key == null) return null;
      final stored = userProfileBox.get(key);
      if (stored == null) return null;
      return UserProfile.fromJson(stored.toJson());
    }

    yield readFresh();
    await for (final _ in userProfileBox.watch()) {
      yield readFresh();
    }
  }

  UserProfile? getUserProfile() {
    return userProfileBox.values.firstOrNull;
  }

  Future<void> clearUserProfile() async {
    await userProfileBox.clear();
  }

  // --- Quizzes ---
  Box<QuizAttempt> get quizAttemptBox =>
      Hive.box<QuizAttempt>(quizAttemptBoxName);

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    await quizAttemptBox.put(attempt.id, attempt);
  }

  Stream<List<QuizAttempt>> watchQuizAttempts() async* {
    yield quizAttemptBox.values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    yield* quizAttemptBox.watch().map(
      (_) =>
          quizAttemptBox.values.toList()
            ..sort((a, b) => b.completedAt.compareTo(a.completedAt)),
    );
  }

  List<QuizAttempt> getQuizAttempts() {
    return quizAttemptBox.values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<QuizAttempt> getAllQuizAttempts() => getQuizAttempts();

  // --- Saved Articles ---
  Box<SavedArticle> get savedArticleBox =>
      Hive.box<SavedArticle>(savedArticleBoxName);

  Future<void> saveSavedArticle(SavedArticle article) async {
    await savedArticleBox.put(article.articleId, article);
  }

  Future<void> deleteSavedArticle(String articleId) async {
    await savedArticleBox.delete(articleId);
  }

  Stream<List<SavedArticle>> watchSavedArticles() async* {
    yield savedArticleBox.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    yield* savedArticleBox.watch().map(
      (_) =>
          savedArticleBox.values.toList()
            ..sort((a, b) => b.savedAt.compareTo(a.savedAt)),
    );
  }

  SavedArticle? getSavedArticle(String articleId) {
    return savedArticleBox.get(articleId);
  }

  List<SavedArticle> getAllSavedArticles() {
    return savedArticleBox.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  // --- Notifications ---
  Box<AppNotification> get appNotificationBox =>
      Hive.box<AppNotification>(appNotificationBoxName);

  Future<void> saveNotification(AppNotification notif) async {
    await appNotificationBox.put(notif.id, notif);
  }

  Future<void> deleteNotification(String id) async {
    await appNotificationBox.delete(id);
  }

  Stream<List<AppNotification>> watchNotifications() async* {
    yield appNotificationBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield* appNotificationBox.watch().map(
      (_) =>
          appNotificationBox.values.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  List<AppNotification> getNotifications() {
    return appNotificationBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveAppNotification(AppNotification n) async {
    await appNotificationBox.put(n.id, n);
  }

  List<AppNotification> getAllAppNotifications() {
    return appNotificationBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<AppNotification>> watchAppNotifications() async* {
    yield getAllAppNotifications();
    yield* appNotificationBox.watch().map((_) => getAllAppNotifications());
  }

  Future<void> deleteAppNotification(String id) async {
    await appNotificationBox.delete(id);
  }

  // --- Subscription ---
  Box<SubscriptionStatus> get subscriptionStatusBox =>
      Hive.box<SubscriptionStatus>(subscriptionStatusBoxName);

  Future<void> saveSubscriptionStatus(SubscriptionStatus status) async {
    await subscriptionStatusBox.put(status.id, status);
  }

  Stream<SubscriptionStatus?> watchSubscriptionStatus() {
    return subscriptionStatusBox.watch().map(
      (_) => subscriptionStatusBox.values.firstOrNull,
    );
  }

  SubscriptionStatus? getSubscriptionStatus() {
    return subscriptionStatusBox.values.firstOrNull;
  }

  // --- Sync Queue ---
  Box<String> get syncQueueBox => Hive.box<String>(syncQueueBoxName);

  Future<void> queueSync(String type, String id) async {
    await enqueueSync(
      type: type,
      action: 'upsert',
      recordId: id,
      payload: null,
    );
  }

  Future<void> enqueueSync({
    required String type,
    required String action,
    required String recordId,
    required dynamic payload,
  }) async {
    final item = SyncItem(
      id: const Uuid().v4(),
      type: type,
      action: action,
      recordId: recordId,
      payload: _normalizePayload(payload),
      retryCount: 0,
      createdAt: DateTime.now().toUtc(),
    );
    await syncQueueBox.put(item.id, item.toJson());
  }

  Future<void> removeFromQueue(String type, String id) async {
    for (final key in syncQueueBox.keys) {
      final item = _syncItemFromStoredValue(key, syncQueueBox.get(key));
      if (item != null && item.type == type && item.recordId == id) {
        await syncQueueBox.delete(key);
      }
    }
  }

  List<String> getPendingSyncs() {
    return syncQueueBox.keys.cast<String>().toList();
  }

  Future<void> processSyncQueue() async {
    if (_isProcessingSyncQueue) return;
    _isProcessingSyncQueue = true;
    try {
      final now = DateTime.now().toUtc();
      final dueItems =
          _getQueuedSyncItems()
              .where(
                (item) =>
                    item.nextRetryAt == null || !item.nextRetryAt!.isAfter(now),
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      for (var start = 0; start < dueItems.length; start += 50) {
        final batch = dueItems.sublist(start, min(start + 50, dueItems.length));
        try {
          final response = await ApiClient.instance.post(
            '/sync/batch',
            data: {'operations': batch.map(_operationForSyncItem).toList()},
          );
          await _applyBatchResult(batch, response.data);
        } on ApiAuthException {
          return;
        } on ApiNetworkException {
          return;
        } on ApiTimeoutException {
          return;
        } catch (error) {
          for (final item in batch) {
            await _scheduleRetry(item);
          }
        }
      }
    } finally {
      _isProcessingSyncQueue = false;
    }
  }

  List<SyncItem> _getQueuedSyncItems() {
    return syncQueueBox.keys
        .map((key) => _syncItemFromStoredValue(key, syncQueueBox.get(key)))
        .whereType<SyncItem>()
        .toList();
  }

  SyncItem? _syncItemFromStoredValue(dynamic key, String? value) {
    if (value == null) return null;
    try {
      return SyncItem.fromJson(value);
    } catch (_) {
      final rawKey = key?.toString() ?? '';
      final parts = rawKey.split(':');
      if (parts.length == 2) {
        return SyncItem(
          id: rawKey,
          type: parts[0],
          action: 'upsert',
          recordId: parts[1],
          retryCount: 0,
          createdAt: DateTime.now().toUtc(),
        );
      }
      return null;
    }
  }

  Map<String, dynamic> _operationForSyncItem(SyncItem item) {
    return {
      'client_operation_id': item.id,
      'type': item.type,
      'action': item.action,
      if (item.action == 'delete' || item.payload == null) 'id': item.recordId,
      if (item.action != 'delete' && item.payload != null) 'data': item.payload,
    };
  }

  Future<void> _applyBatchResult(List<SyncItem> batch, dynamic data) async {
    final results = _extractBatchResults(data);
    if (results == null) {
      for (final item in batch) {
        await syncQueueBox.delete(item.id);
      }
      return;
    }

    for (final item in batch) {
      final result = results[item.id] ?? results[item.recordId];
      if (result == true) {
        await syncQueueBox.delete(item.id);
      } else {
        await _scheduleRetry(item);
      }
    }
  }

  Map<String, bool>? _extractBatchResults(dynamic data) {
    final payload = data is Map && data['data'] is Map ? data['data'] : data;
    final rawResults = payload is Map
        ? payload['results'] ?? payload['operations']
        : null;
    if (rawResults is! List) return null;

    return {
      for (final result in rawResults)
        if (result is Map)
          (result['client_operation_id'] ?? result['id'] ?? result['record_id'])
                  .toString():
              result['success'] == true || result['status'] == 'success',
    };
  }

  Future<void> _scheduleRetry(SyncItem item) async {
    final nextRetryCount = item.retryCount + 1;
    if (nextRetryCount > 10) {
      await syncQueueBox.delete(item.id);
      return;
    }

    final retryAt = _nextRetryAt(nextRetryCount);
    final updated = item.copyWith(
      retryCount: nextRetryCount,
      nextRetryAt: retryAt,
    );
    await syncQueueBox.put(updated.id, updated.toJson());
  }

  DateTime _nextRetryAt(int retryCount) {
    final now = DateTime.now().toUtc();
    if (retryCount <= 1) return now;
    if (retryCount == 2) return now.add(const Duration(seconds: 30));
    if (retryCount == 3) return now.add(const Duration(minutes: 5));
    return now.add(const Duration(hours: 1));
  }

  Map<String, dynamic>? _normalizePayload(dynamic payload) {
    if (payload == null) return null;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    if (payload is String && payload.isEmpty) return null;
    return {'value': payload};
  }

  // --- Scoping / Logout ---
  Future<void> clearAllUserData() async {
    await moodBox.clear();
    await journalBox.clear();
    await Hive.box<ChatMessage>(chatMessageBoxName).clear();
    await Hive.box<ChatConversation>(chatConversationBoxName).clear();
    await Hive.box<SafetyPlan>(safetyPlanBoxName).clear();
    await userProfileBox.clear();
    await Hive.box<QuizAttempt>(quizAttemptBoxName).clear();
    await Hive.box<SavedArticle>(savedArticleBoxName).clear();
    await Hive.box<AppNotification>(appNotificationBoxName).clear();
    await Hive.box<SubscriptionStatus>(subscriptionStatusBoxName).clear();
    await syncQueueBox.clear();
  }
}
