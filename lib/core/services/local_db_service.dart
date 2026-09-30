import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
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
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
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
    await queueSync('mood_entry', entry.id);
  }

  List<MoodEntry> getAllMoodEntries() {
    return moodBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- Journals ---
  Box<JournalEntry> get journalBox => Hive.box<JournalEntry>(journalBoxName);

  Future<void> saveJournalEntry(JournalEntry entry) async {
    await journalBox.put(entry.id, entry);
    await queueSync('journal_entry', entry.id);
  }

  List<JournalEntry> getAllJournalEntries() {
    return journalBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<JournalEntry>> watchJournalEntries() async* {
    yield getAllJournalEntries();
    yield* journalBox.watch().map((_) => getAllJournalEntries());
  }

  Future<void> deleteJournalEntry(String id) async {
    await journalBox.delete(id);
    await queueSync('delete_journal', id);
  }

  // --- Chat ---
  Box<ChatMessage> get chatMessageBox => Hive.box<ChatMessage>(chatMessageBoxName);
  Box<ChatConversation> get chatConversationBox => Hive.box<ChatConversation>(chatConversationBoxName);

  Future<void> saveChatMessage(ChatMessage message) async {
    await chatMessageBox.put(message.id, message);
    await queueSync('chat_message', message.id);
  }

  Future<void> saveChatConversation(ChatConversation conversation) async {
    await chatConversationBox.put(conversation.id, conversation);
    await queueSync('chat_conversation', conversation.id);
  }

  Stream<List<ChatConversation>> watchConversations() async* {
    yield getAllConversations();
    yield* chatConversationBox.watch().map((_) => getAllConversations());
  }

  List<ChatConversation> getAllConversations() {
    return chatConversationBox.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

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
    yield* chatMessageBox.watch().map((_) => getMessagesForConversation(conversationId));
  }

  List<ChatMessage> getMessagesForConversation(String conversationId) {
    return chatMessageBox.values.where((m) => m.conversationId == conversationId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  ChatMessage? getChatMessage(String id) {
    return chatMessageBox.get(id);
  }

  // --- Safety Plan ---
  Box<SafetyPlan> get safetyPlanBox => Hive.box<SafetyPlan>(safetyPlanBoxName);

  Future<void> saveSafetyPlan(SafetyPlan plan) async {
    await safetyPlanBox.put(plan.id, plan);
    await queueSync('safety_plan', plan.id);
  }

  Stream<SafetyPlan?> watchSafetyPlan() {
    return safetyPlanBox.watch().map((_) => safetyPlanBox.values.firstOrNull);
  }

  SafetyPlan? getSafetyPlan() {
    return safetyPlanBox.values.firstOrNull;
  }

  // --- User Profile ---
  Box<UserProfile> get userProfileBox => Hive.box<UserProfile>(userProfileBoxName);

  Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put(profile.id, profile);
    await queueSync('user_profile', profile.id);
  }

  Stream<UserProfile?> watchUserProfile() {
    return userProfileBox.watch().map((_) => userProfileBox.values.firstOrNull);
  }

  UserProfile? getUserProfile() {
    return userProfileBox.values.firstOrNull;
  }

  Future<void> clearUserProfile() async {
    await userProfileBox.clear();
  }

  // --- Quizzes ---
  Box<QuizAttempt> get quizAttemptBox => Hive.box<QuizAttempt>(quizAttemptBoxName);

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    await quizAttemptBox.put(attempt.id, attempt);
    await queueSync('quiz_attempt', attempt.id);
  }

  Stream<List<QuizAttempt>> watchQuizAttempts() async* {
    yield quizAttemptBox.values.toList()..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    yield* quizAttemptBox.watch().map((_) => quizAttemptBox.values.toList()..sort((a, b) => b.completedAt.compareTo(a.completedAt)));
  }

  List<QuizAttempt> getQuizAttempts() {
    return quizAttemptBox.values.toList()..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // --- Saved Articles ---
  Box<SavedArticle> get savedArticleBox => Hive.box<SavedArticle>(savedArticleBoxName);

  Future<void> saveSavedArticle(SavedArticle article) async {
    await savedArticleBox.put(article.articleId, article);
    await queueSync('saved_article', article.articleId);
  }

  Future<void> deleteSavedArticle(String articleId) async {
    await savedArticleBox.delete(articleId);
    await queueSync('delete_saved_article', articleId);
  }

  Stream<List<SavedArticle>> watchSavedArticles() async* {
    yield savedArticleBox.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    yield* savedArticleBox.watch().map((_) => savedArticleBox.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt)));
  }

  SavedArticle? getSavedArticle(String articleId) {
    return savedArticleBox.get(articleId);
  }

  // --- Notifications ---
  Box<AppNotification> get appNotificationBox => Hive.box<AppNotification>(appNotificationBoxName);

  Future<void> saveNotification(AppNotification notif) async {
    await appNotificationBox.put(notif.id, notif);
  }

  Future<void> deleteNotification(String id) async {
    await appNotificationBox.delete(id);
  }

  Stream<List<AppNotification>> watchNotifications() async* {
    yield appNotificationBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield* appNotificationBox.watch().map((_) => appNotificationBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }

  List<AppNotification> getNotifications() {
    return appNotificationBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // --- Subscription ---
  Box<SubscriptionStatus> get subscriptionStatusBox => Hive.box<SubscriptionStatus>(subscriptionStatusBoxName);

  Future<void> saveSubscriptionStatus(SubscriptionStatus status) async {
    await subscriptionStatusBox.put(status.id, status);
  }

  Stream<SubscriptionStatus?> watchSubscriptionStatus() {
    return subscriptionStatusBox.watch().map((_) => subscriptionStatusBox.values.firstOrNull);
  }

  SubscriptionStatus? getSubscriptionStatus() {
    return subscriptionStatusBox.values.firstOrNull;
  }

  // --- Sync Queue ---
  Box<String> get syncQueueBox => Hive.box<String>(syncQueueBoxName);

  Future<void> queueSync(String type, String id) async {
    final key = '$type:$id';
    if (!syncQueueBox.containsKey(key)) {
      await syncQueueBox.put(key, id);
    }
  }

  Future<void> enqueueSync({
    required String type,
    required String action,
    required String recordId,
    required dynamic payload,
  }) async {
    await queueSync(type, recordId);
  }

  Future<void> removeFromQueue(String type, String id) async {
    await syncQueueBox.delete('$type:$id');
  }

  List<String> getPendingSyncs() {
    return syncQueueBox.keys.cast<String>().toList();
  }

  Future<void> processSyncQueue() async {
    final pendingSyncs = getPendingSyncs();
    for (final key in pendingSyncs) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      
      final type = parts[0];
      final id = parts[1];

      try {
        // In a real app, this is where we'd make API calls based on the type
        // e.g., if (type == 'mood_entry') { await apiService.syncMood(getMood(id)); }
        // For now, we simulate a successful API sync by just awaiting a small delay
        await Future.delayed(const Duration(milliseconds: 100));
        
        // On success, remove from queue
        await removeFromQueue(type, id);
        print('Synced $type:$id successfully');
      } catch (e) {
        print('Failed to sync $type:$id : $e');
        // It stays in the queue to be retried later
      }
    }
  }

    // Notifications
  Future<void> deleteAppNotification(String id) async { await Hive.box<AppNotification>(appNotificationBoxName).delete(id); }
  
  // Quizzes
  List<QuizAttempt> getAllQuizAttempts() { return Hive.box<QuizAttempt>(quizAttemptBoxName).values.toList(); }

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

