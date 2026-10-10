import '../storage/encrypted_hive.dart';
import '../storage/hive_files.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'dart:math';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/sync_item.dart';
import '../models/sync_summary.dart';
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
import '../models/user_preferences.dart';
import 'package:flutter/foundation.dart';
import '../storage/token_storage.dart';

class LocalDbService {
  // Singleton pattern
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();
  static LocalDbService get instance => _instance;
  bool _isProcessingSyncQueue = false;
  bool syncPaused = false;
  bool _forceSyncRequested = false;
  Future<void> waitForSyncIdle() async {
    await _currentSync;
  }

  Future<SyncSummary>? _currentSync;
  Future<void> _accountActivation = Future.value();
  final _syncResults = StreamController<SyncSummary>.broadcast();
  Stream<SyncSummary> get syncResults => _syncResults.stream;
  String? _activeUser;
  final _accountChanges = StreamController<void>.broadcast();
  String boxName(String base) => _activeUser == null
      ? base
      : '${base}_user_${_activeUser!.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
  bool isBoxOpen(String base) => EncryptedHive.isBoxOpen(boxName(base));

  Future<void> activateAccount(
    String userId, {
    String? email,
    bool registration = false,
    String? expiredAccount,
  }) {
    final task = _accountActivation.then((_) async {
      if (expiredAccount != null &&
          (syncPaused ||
              _activeUser != expiredAccount ||
              await TokenStorage().getToken() != null)) {
        return;
      }
      final wasPaused = syncPaused;
      syncPaused = true;
      await waitForSyncIdle();
      try {
        await _activateAccount(
          userId,
          email: email,
          registration: registration,
        );
      } finally {
        syncPaused = wasPaused;
      }
    });
    _accountActivation = task.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return task;
  }

  Future<void> _activateAccount(
    String userId, {
    String? email,
    bool registration = false,
  }) async {
    final registry = await EncryptedHive.openBox<dynamic>('device_registry');
    if (!registry.containsKey('legacy_email')) {
      final legacy = EncryptedHive.isBoxOpen(userProfileBoxName)
          ? EncryptedHive.box<UserProfile>(
              userProfileBoxName,
            ).values.firstOrNull
          : null;
      await registry.put('legacy_email', legacy?.email.toLowerCase() ?? '');
    }
    final legacyEmail = registry.get('legacy_email') as String;
    final isGuest = userId.startsWith('guest_');
    final fromGuest = _activeUser?.startsWith('guest_') == true;
    final adoptLegacy =
        !isGuest &&
        legacyEmail.isNotEmpty &&
        legacyEmail == email?.toLowerCase() &&
        registry.get('legacy_claimed_by') == null;
    final adopt = adoptLegacy || (!isGuest && fromGuest && registration);
    String sourceName(String base) =>
        adoptLegacy ? base : (fromGuest ? boxName(base) : base);
    final scope = userId.codeUnits
        .map((c) => c.toRadixString(16).padLeft(2, '0'))
        .join();
    Future<void> open<T>(
      String base,
      T Function(Map<String, dynamic>) clone,
    ) async {
      final target = await EncryptedHive.openBox<T>('${base}_user_$scope');
      if (adopt &&
          target.isEmpty &&
          EncryptedHive.isBoxOpen(sourceName(base))) {
        final source = EncryptedHive.box<T>(sourceName(base));
        for (final key in source.keys) {
          final dynamic value = source.get(key);
          if (value != null) {
            await target.put(
              key,
              clone(Map<String, dynamic>.from(value.toJson() as Map)),
            );
          }
        }
      }
    }

    await open<MoodEntry>(moodBoxName, MoodEntry.fromJson);
    await open<JournalEntry>(journalBoxName, JournalEntry.fromJson);
    await open<ChatMessage>(chatMessageBoxName, ChatMessage.fromJson);
    await open<ChatConversation>(
      chatConversationBoxName,
      ChatConversation.fromJson,
    );
    await open<SafetyPlan>(safetyPlanBoxName, SafetyPlan.fromJson);
    await open<UserProfile>(userProfileBoxName, UserProfile.fromJson);
    await open<QuizAttempt>(quizAttemptBoxName, QuizAttempt.fromJson);
    await open<SavedArticle>(savedArticleBoxName, SavedArticle.fromJson);
    await open<AppNotification>(
      appNotificationBoxName,
      AppNotification.fromJson,
    );
    await open<SubscriptionStatus>(
      subscriptionStatusBoxName,
      SubscriptionStatus.fromJson,
    );
    if (!Hive.isAdapterRegistered(11)) {
      if (!Hive.isAdapterRegistered(UserPreferencesAdapter().typeId)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
    }
    await open<UserPreferences>(
      userPreferencesBoxName,
      UserPreferences.fromJson,
    );
    final queue = await EncryptedHive.openBox<String>(
      '${syncQueueBoxName}_user_$scope',
    );
    final settings = await EncryptedHive.openBox<dynamic>(
      '${userSettingsBoxName}_user_$scope',
    );
    if (adopt &&
        queue.isEmpty &&
        EncryptedHive.isBoxOpen(sourceName(syncQueueBoxName))) {
      await queue.putAll(
        EncryptedHive.box<String>(sourceName(syncQueueBoxName)).toMap(),
      );
    }
    if (adopt &&
        settings.isEmpty &&
        EncryptedHive.isBoxOpen(sourceName(userSettingsBoxName))) {
      await settings.putAll(
        EncryptedHive.box<dynamic>(sourceName(userSettingsBoxName)).toMap(),
      );
    }
    // Before login, copy onboarding answers only; guest history remains separate.
    if (!adopt &&
        !isGuest &&
        (fromGuest || (legacyEmail.isEmpty && _activeUser == null)) &&
        EncryptedHive.isBoxOpen(sourceName(userPreferencesBoxName))) {
      final source = EncryptedHive.box<UserPreferences>(
        sourceName(userPreferencesBoxName),
      );
      final target = EncryptedHive.box<UserPreferences>(
        '${userPreferencesBoxName}_user_$scope',
      );
      final preferences = source.get('current');
      if (target.isEmpty && preferences != null) {
        await target.put(
          'current',
          UserPreferences.fromJson(preferences.toJson()),
        );
      }
      if (queue.isEmpty &&
          EncryptedHive.isBoxOpen(sourceName(syncQueueBoxName))) {
        for (final key in EncryptedHive.box<String>(
          sourceName(syncQueueBoxName),
        ).keys) {
          final value = EncryptedHive.box<String>(
            sourceName(syncQueueBoxName),
          ).get(key)!;
          try {
            if (SyncItem.fromJson(value).type == 'user_preferences') {
              await queue.put(key, value);
            }
          } catch (_) {}
        }
      }
    }
    if (fromGuest && !isGuest) {
      await registry.put(
        'guest_epoch',
        (registry.get('guest_epoch', defaultValue: 0) as int) + 1,
      );
    }
    if (adoptLegacy) {
      await registry.put('legacy_claimed_by', userId);
    }
    _activeUser = userId;
    await registry.put('active_user_id', userId);
    _accountChanges.add(null);
  }

  Future<void> activateGuest() async {
    await waitForSyncIdle();
    final registry = await EncryptedHive.openBox<dynamic>('device_registry');
    final epoch = registry.get('guest_epoch', defaultValue: 0) as int;
    await activateAccount('guest_$epoch');
  }

  Future<void> activateGuestAfterSync() async {
    final account = _activeUser;
    if (account == null || account.startsWith('guest_')) return;
    await waitForSyncIdle();
    // A new login while the expired request completes must retain its account.
    if (!syncPaused &&
        account == _activeUser &&
        await TokenStorage().getToken() == null) {
      final registry = await EncryptedHive.openBox<dynamic>('device_registry');
      final epoch = registry.get('guest_epoch', defaultValue: 0) as int;
      await activateAccount('guest_$epoch', expiredAccount: account);
    }
  }

  Stream<T> _watchScoped<T>(
    T Function() read,
    Stream<BoxEvent> Function() events,
  ) => Stream<T>.multi((controller) {
    StreamSubscription<BoxEvent>? records;
    void bind() {
      records?.cancel();
      try {
        controller.add(read());
        records = events().listen((_) {
          try {
            controller.add(read());
          } catch (error, stack) {
            controller.addError(error, stack);
          }
        }, onError: controller.addError);
      } catch (error, stack) {
        controller.addError(error, stack);
      }
    }

    final account = _accountChanges.stream.listen((_) => bind());
    bind();
    controller.onCancel = () async {
      await records?.cancel();
      await account.cancel();
    };
  });

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
  static const String userPreferencesBoxName = 'user_preferences';
  static const String userSettingsBoxName = 'user_settings';

  Future<void> init() async {
    await Hive.initFlutter();
    final installPrefs = await SharedPreferences.getInstance();
    EncryptedHive.prepareInstall(
      markerSet: installPrefs.getBool('install_marker_set') ?? false,
      hasLocalFiles: await hasLocalHiveFiles(),
    );

    // Register Adapters
    if (!Hive.isAdapterRegistered(MoodEntryAdapter().typeId)) {
      Hive.registerAdapter(MoodEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(JournalEntryAdapter().typeId)) {
      Hive.registerAdapter(JournalEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(ChatMessageAdapter().typeId)) {
      Hive.registerAdapter(ChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(ChatConversationAdapter().typeId)) {
      Hive.registerAdapter(ChatConversationAdapter());
    }
    if (!Hive.isAdapterRegistered(SafetyPlanAdapter().typeId)) {
      Hive.registerAdapter(SafetyPlanAdapter());
    }
    if (!Hive.isAdapterRegistered(UserProfileAdapter().typeId)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(QuizAttemptAdapter().typeId)) {
      Hive.registerAdapter(QuizAttemptAdapter());
    }
    if (!Hive.isAdapterRegistered(SavedArticleAdapter().typeId)) {
      Hive.registerAdapter(SavedArticleAdapter());
    }
    if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
      Hive.registerAdapter(AppNotificationAdapter());
    }
    if (!Hive.isAdapterRegistered(SubscriptionStatusAdapter().typeId)) {
      Hive.registerAdapter(SubscriptionStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(UserPreferencesAdapter().typeId)) {
      Hive.registerAdapter(UserPreferencesAdapter());
    }

    // Open Boxes
    await EncryptedHive.openBox<MoodEntry>(moodBoxName);
    await EncryptedHive.openBox<JournalEntry>(journalBoxName);
    await EncryptedHive.openBox<ChatMessage>(chatMessageBoxName);
    await EncryptedHive.openBox<ChatConversation>(chatConversationBoxName);
    await EncryptedHive.openBox<SafetyPlan>(safetyPlanBoxName);
    await EncryptedHive.openBox<UserProfile>(userProfileBoxName);
    await EncryptedHive.openBox<QuizAttempt>(quizAttemptBoxName);
    await EncryptedHive.openBox<SavedArticle>(savedArticleBoxName);
    await EncryptedHive.openBox<AppNotification>(appNotificationBoxName);
    await EncryptedHive.openBox<SubscriptionStatus>(subscriptionStatusBoxName);
    await EncryptedHive.openBox<String>(syncQueueBoxName);
    await EncryptedHive.openBox<UserPreferences>(userPreferencesBoxName);
    await EncryptedHive.openBox<dynamic>(userSettingsBoxName);
    // Encrypt inactive accounts too; do not leave PHI awaiting their next login.
    for (final name in await legacyHiveNames(moodBox.path)) {
      Future<void> migrate<T>(String base) async {
        if (name.startsWith('${base}_user_')) {
          await EncryptedHive.openBox<T>(name);
        }
      }

      await migrate<MoodEntry>(moodBoxName);
      await migrate<JournalEntry>(journalBoxName);
      await migrate<ChatMessage>(chatMessageBoxName);
      await migrate<ChatConversation>(chatConversationBoxName);
      await migrate<SafetyPlan>(safetyPlanBoxName);
      await migrate<UserProfile>(userProfileBoxName);
      await migrate<QuizAttempt>(quizAttemptBoxName);
      await migrate<SavedArticle>(savedArticleBoxName);
      await migrate<AppNotification>(appNotificationBoxName);
      await migrate<SubscriptionStatus>(subscriptionStatusBoxName);
      await migrate<UserPreferences>(userPreferencesBoxName);
      await migrate<String>(syncQueueBoxName);
      await migrate<dynamic>(userSettingsBoxName);
    }
    Timer.periodic(const Duration(minutes: 5), (_) {
      processSyncQueue();
    });
    final registry = await EncryptedHive.openBox<dynamic>('device_registry');
    final active = registry.get('active_user_id') as String?;
    if (active != null &&
        (active.startsWith('guest_') ||
            await TokenStorage().getToken() != null)) {
      await activateAccount(active);
    } else if (await TokenStorage().getToken() == null) {
      await activateGuest();
    }
    Future.microtask(() => processSyncQueue());
  }

  // --- Moods ---
  Box<MoodEntry> get moodBox =>
      EncryptedHive.box<MoodEntry>(boxName(moodBoxName));

  Future<void> saveMoodEntry(MoodEntry entry) async {
    await moodBox.put(entry.id, entry);
  }

  List<MoodEntry> getAllMoodEntries() {
    return moodBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<MoodEntry>> watchMoodEntries() =>
      _watchScoped(getAllMoodEntries, () => moodBox.watch());

  Future<void> deleteMoodEntry(String id) async {
    await moodBox.delete(id);
  }

  // --- Journals ---
  Box<JournalEntry> get journalBox =>
      EncryptedHive.box<JournalEntry>(boxName(journalBoxName));

  Future<void> saveJournalEntry(JournalEntry entry) async {
    await journalBox.put(entry.id, entry);
  }

  List<JournalEntry> getAllJournalEntries() {
    return journalBox.values.where((entry) => !entry.isDraft).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Stream<List<JournalEntry>> watchJournalEntries() =>
      _watchScoped(getAllJournalEntries, () => journalBox.watch());

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
      EncryptedHive.box<ChatMessage>(boxName(chatMessageBoxName));
  Box<ChatConversation> get chatConversationBox =>
      EncryptedHive.box<ChatConversation>(boxName(chatConversationBoxName));

  Future<void> saveChatMessage(ChatMessage message) async {
    await chatMessageBox.put(message.id, message);
  }

  Future<void> saveChatConversation(ChatConversation conversation) async {
    await chatConversationBox.put(conversation.id, conversation);
  }

  Stream<List<ChatConversation>> watchConversations() =>
      _watchScoped(getAllConversations, () => chatConversationBox.watch());

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

  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _watchScoped(
        () => getMessagesForConversation(conversationId),
        () => chatMessageBox.watch(),
      );

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
  Box<SafetyPlan> get safetyPlanBox =>
      EncryptedHive.box<SafetyPlan>(boxName(safetyPlanBoxName));

  Future<void> saveSafetyPlan(SafetyPlan plan) async {
    await safetyPlanBox.put(plan.id, plan);
    for (final key in safetyPlanBox.keys.toList()) {
      if (key != plan.id) await safetyPlanBox.delete(key);
    }
  }

  Stream<SafetyPlan?> watchSafetyPlan() =>
      _watchScoped(getSafetyPlan, () => safetyPlanBox.watch());

  SafetyPlan? getSafetyPlan() {
    return safetyPlanBox.values.firstOrNull;
  }

  Future<void> clearSafetyPlan() async {
    await safetyPlanBox.clear();
  }

  // --- User Profile ---
  Box<UserProfile> get userProfileBox =>
      EncryptedHive.box<UserProfile>(boxName(userProfileBoxName));

  bool get isUserProfileBoxOpen => isBoxOpen(userProfileBoxName);

  Future<void> saveUserProfile(UserProfile profile) async {
    await userProfileBox.put(profile.id, profile);
    await (await settingsBox()).put('current_profile_id', profile.id);
    _accountChanges.add(null);
  }

  Stream<UserProfile?> watchUserProfile() => _watchScoped(() {
    final stored = getUserProfile();
    return stored == null ? null : UserProfile.fromJson(stored.toJson());
  }, () => userProfileBox.watch());

  UserProfile? getUserProfile() {
    final key = isBoxOpen(userSettingsBoxName)
        ? EncryptedHive.box<dynamic>(
            boxName(userSettingsBoxName),
          ).get('current_profile_id')
        : null;
    return (key == null ? null : userProfileBox.get(key)) ??
        userProfileBox.values.firstOrNull;
  }

  Future<void> clearUserProfile() async {
    await userProfileBox.clear();
  }

  // --- Quizzes ---
  Box<QuizAttempt> get quizAttemptBox =>
      EncryptedHive.box<QuizAttempt>(boxName(quizAttemptBoxName));

  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
    await quizAttemptBox.put(attempt.id, attempt);
  }

  Stream<List<QuizAttempt>> watchQuizAttempts() =>
      _watchScoped(getAllQuizAttempts, () => quizAttemptBox.watch());

  List<QuizAttempt> getQuizAttempts() {
    return quizAttemptBox.values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  List<QuizAttempt> getAllQuizAttempts() => getQuizAttempts();

  // --- Saved Articles ---
  Box<SavedArticle> get savedArticleBox =>
      EncryptedHive.box<SavedArticle>(boxName(savedArticleBoxName));

  Future<void> saveSavedArticle(SavedArticle article) async {
    await savedArticleBox.put(article.articleId, article);
  }

  Future<void> deleteSavedArticle(String articleId) async {
    await savedArticleBox.delete(articleId);
  }

  Stream<List<SavedArticle>> watchSavedArticles() =>
      _watchScoped(getAllSavedArticles, () => savedArticleBox.watch());

  SavedArticle? getSavedArticle(String articleId) {
    return savedArticleBox.get(articleId);
  }

  List<SavedArticle> getAllSavedArticles() {
    return savedArticleBox.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  // --- Notifications ---
  Box<AppNotification> get appNotificationBox =>
      EncryptedHive.box<AppNotification>(boxName(appNotificationBoxName));

  Future<void> saveNotification(AppNotification notif) async {
    await appNotificationBox.put(notif.id, notif);
  }

  Future<void> deleteNotification(String id) async {
    await appNotificationBox.delete(id);
  }

  Stream<List<AppNotification>> watchNotifications() =>
      _watchScoped(getNotifications, () => appNotificationBox.watch());

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

  Stream<List<AppNotification>> watchAppNotifications() =>
      _watchScoped(getAllAppNotifications, () => appNotificationBox.watch());

  Future<void> deleteAppNotification(String id) async {
    await appNotificationBox.delete(id);
  }

  // --- Subscription ---
  Box<SubscriptionStatus> get subscriptionStatusBox =>
      EncryptedHive.box<SubscriptionStatus>(boxName(subscriptionStatusBoxName));

  Future<void> saveSubscriptionStatus(SubscriptionStatus status) async {
    await subscriptionStatusBox.put(status.id, status);
  }

  Stream<SubscriptionStatus?> watchSubscriptionStatus() {
    return _watchScoped(
      getSubscriptionStatus,
      () => subscriptionStatusBox.watch(),
    );
  }

  SubscriptionStatus? getSubscriptionStatus() {
    return subscriptionStatusBox.values.firstOrNull;
  }

  // --- Onboarding preferences ---
  Future<Box<UserPreferences>> preferencesBox() async {
    if (!Hive.isAdapterRegistered(11)) {
      if (!Hive.isAdapterRegistered(UserPreferencesAdapter().typeId)) {
        Hive.registerAdapter(UserPreferencesAdapter());
      }
    }
    return isBoxOpen(userPreferencesBoxName)
        ? EncryptedHive.box<UserPreferences>(boxName(userPreferencesBoxName))
        : EncryptedHive.openBox<UserPreferences>(
            boxName(userPreferencesBoxName),
          );
  }

  Future<Box<dynamic>> settingsBox() async => isBoxOpen(userSettingsBoxName)
      ? EncryptedHive.box<dynamic>(boxName(userSettingsBoxName))
      : EncryptedHive.openBox<dynamic>(boxName(userSettingsBoxName));

  Future<UserPreferences?> getUserPreferences() async =>
      (await preferencesBox()).get('current');

  Future<void> saveUserPreferences(UserPreferences preferences) async {
    await (await preferencesBox()).put('current', preferences);
    final settings = await settingsBox();
    await settings.put('onboarding_preferences', preferences.toJson());
    if (!settings.containsKey('has_seen_tour')) {
      await settings.put('has_seen_tour', false);
    }
    // Keep a durable sync intent until the backend accepts this type.
    final recordId =
        settings.get('preferences_sync_id') as String? ?? const Uuid().v4();
    await settings.put('preferences_sync_id', recordId);
    if (!isBoxOpen(syncQueueBoxName)) {
      await EncryptedHive.openBox<String>(boxName(syncQueueBoxName));
    }
    await removeFromQueue('user_preferences', recordId);
    await enqueueSync(
      type: 'user_preferences',
      action: 'upsert',
      recordId: recordId,
      payload: {'id': recordId, ...preferences.toJson()},
    );
    debugPrint('Onboarding preferences saved locally and queued for sync.');
  }

  // --- Sync Queue ---
  Box<String> get syncQueueBox =>
      EncryptedHive.box<String>(boxName(syncQueueBoxName));

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
    final predecessors = pendingItems;
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
    // Keep the newest intent for a record, including an in-flight predecessor.
    // Write first so a crash cannot erase the only durable queued change.
    if (action == 'upsert' || action == 'delete') {
      for (final old in predecessors) {
        if (old.id != item.id &&
            old.type == type &&
            old.recordId == recordId &&
            (old.action == 'upsert' || old.action == 'delete')) {
          await syncQueueBox.delete(old.id);
        }
      }
    }
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

  List<SyncItem> get pendingItems =>
      isBoxOpen(syncQueueBoxName) ? _getQueuedSyncItems() : [];
  bool hasPending(String type, String id) =>
      pendingItems.any((item) => item.type == type && item.recordId == id);
  Stream<List<SyncItem>> watchPendingItems() => isBoxOpen(syncQueueBoxName)
      ? _watchScoped(() => pendingItems, () => syncQueueBox.watch())
      : Stream.value([]);

  Future<SyncSummary> processSyncQueue({bool force = false}) {
    if (syncPaused ||
        _activeUser?.startsWith('guest_') == true ||
        !isBoxOpen(syncQueueBoxName)) {
      return Future.value(const SyncSummary());
    }
    if (_isProcessingSyncQueue) {
      _forceSyncRequested |= force;
      return _currentSync ?? Future.value(const SyncSummary());
    }
    _currentSync = _processSyncQueue(force: force);
    return _currentSync!;
  }

  Future<SyncSummary> _processSyncQueue({required bool force}) async {
    _isProcessingSyncQueue = true;
    var synced = 0;
    var failed = 0;
    String? errorCode;
    final attempted = <String>{};
    try {
      // Repair duplicate intents already stored by older app versions.
      final latest = <String, SyncItem>{};
      final stored = pendingItems
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final item in stored) {
        if (item.action != 'upsert' && item.action != 'delete') continue;
        final key = '${item.type}:${item.recordId}';
        final old = latest[key];
        if (old != null) await syncQueueBox.delete(old.id);
        latest[key] = item;
      }
      while (!syncPaused) {
        final now = DateTime.now().toUtc();
        final forcePass = force || _forceSyncRequested;
        _forceSyncRequested = false;
        final dueItems =
            _getQueuedSyncItems()
                .where(
                  (item) =>
                      !attempted.contains(item.id) &&
                      (forcePass ||
                          item.nextRetryAt == null ||
                          !item.nextRetryAt!.isAfter(now)),
                )
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        if (dueItems.isEmpty) break;

        for (var start = 0; start < dueItems.length; start += 50) {
          if (syncPaused) break;
          final batch = dueItems
              .sublist(start, min(start + 50, dueItems.length))
              .where((item) => syncQueueBox.containsKey(item.id))
              .toList();
          if (batch.isEmpty) continue;
          attempted.addAll(batch.map((item) => item.id));
          try {
            final response = await ApiClient.instance.post(
              '/sync/batch',
              data: {'operations': batch.map(_operationForSyncItem).toList()},
            );
            final result = await _applyBatchResult(batch, response.data);
            synced += result.synced;
            failed += result.failed;
            errorCode ??= result.errorCode;
          } on ApiAuthException catch (error) {
            failed += dueItems.length - start;
            errorCode = error.statusCode == 403
                ? 'access_denied'
                : 'session_expired';
            for (final item in batch) {
              await _scheduleRetry(item, errorCode: errorCode);
            }
            return _publishSyncSummary(synced, failed, errorCode);
          } on ApiNetworkException {
            failed += dueItems.length - start;
            errorCode = 'connection';
            for (final item in batch) {
              await _scheduleRetry(item, errorCode: errorCode);
            }
            return _publishSyncSummary(synced, failed, errorCode);
          } on ApiTimeoutException {
            failed += dueItems.length - start;
            errorCode = 'connection';
            for (final item in batch) {
              await _scheduleRetry(item, errorCode: errorCode);
            }
            return _publishSyncSummary(synced, failed, errorCode);
          } catch (error) {
            failed += batch.length;
            errorCode = error is ApiSecureConnectionException
                ? 'secure_connection'
                : error is ApiServerException
                ? 'server'
                : error is ApiValidationException
                ? 'invalid_payload'
                : 'unknown';
            for (final item in batch) {
              await _scheduleRetry(item, errorCode: errorCode);
            }
          }
        }
      }
    } finally {
      _isProcessingSyncQueue = false;
    }
    failed = pendingItems.where((item) => attempted.contains(item.id)).length;
    return _publishSyncSummary(synced, failed, errorCode);
  }

  SyncSummary _publishSyncSummary(int synced, int failed, String? errorCode) {
    final summary = SyncSummary(
      synced: synced,
      failed: failed,
      errorCode: errorCode,
    );
    if (summary.attempted > 0) _syncResults.add(summary);
    return summary;
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
    final payload = item.payload ?? _cachedSyncPayload(item);
    return {
      'client_operation_id': item.id,
      'type': item.type,
      'action': item.action,
      if (item.action == 'delete' || payload == null) 'id': item.recordId,
      if (item.action != 'delete' && payload != null) 'data': payload,
    };
  }

  Map<String, dynamic>? _cachedSyncPayload(SyncItem item) {
    final boxes = {
      'mood_entry': moodBoxName,
      'journal_entry': journalBoxName,
      'chat_conversation': chatConversationBoxName,
      'chat_message': chatMessageBoxName,
      'safety_plan': safetyPlanBoxName,
      'user_profile': userProfileBoxName,
      'quiz_attempt': quizAttemptBoxName,
      'saved_article': savedArticleBoxName,
      'app_notification': appNotificationBoxName,
      'subscription': subscriptionStatusBoxName,
      'subscription_status': subscriptionStatusBoxName,
      'user_preferences': userPreferencesBoxName,
    };
    final base = boxes[item.type];
    if (base == null || !isBoxOpen(base)) return null;
    final Iterable<dynamic> records = switch (item.type) {
      'mood_entry' => moodBox.values,
      'journal_entry' => journalBox.values,
      'chat_conversation' => chatConversationBox.values,
      'chat_message' => chatMessageBox.values,
      'safety_plan' => safetyPlanBox.values,
      'user_profile' => userProfileBox.values,
      'quiz_attempt' => quizAttemptBox.values,
      'saved_article' => savedArticleBox.values,
      'app_notification' => appNotificationBox.values,
      'subscription' || 'subscription_status' => subscriptionStatusBox.values,
      'user_preferences' => EncryptedHive.box<UserPreferences>(
        boxName(base),
      ).values,
      _ => const [],
    };
    for (final dynamic value in records) {
      final json = Map<String, dynamic>.from(value.toJson() as Map);
      if (json['id']?.toString() == item.recordId ||
          (item.type == 'saved_article' &&
              json['article_id']?.toString() == item.recordId) ||
          item.type == 'user_preferences') {
        return {'id': item.recordId, ...json};
      }
    }
    return null;
  }

  Future<SyncSummary> _applyBatchResult(
    List<SyncItem> batch,
    dynamic data,
  ) async {
    final results = _extractBatchResults(data);
    var synced = 0;
    String? errorCode;
    for (final item in batch) {
      final result = results?[item.id] ?? results?[item.recordId];
      if (result?['success'] == true || result?['status'] == 'success') {
        synced++;
        await syncQueueBox.delete(item.id);
      } else {
        final code = _safeSyncError(result?['error_code']);
        errorCode ??= code;
        await _scheduleRetry(item, errorCode: code);
      }
    }
    return SyncSummary(
      synced: synced,
      failed: batch.length - synced,
      errorCode: errorCode,
    );
  }

  Map<String, Map>? _extractBatchResults(dynamic data) {
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
              result,
    };
  }

  String? _safeSyncError(dynamic code) =>
      const {
        'invalid_payload',
        'unknown_type',
        'unknown_action',
        'ownership_conflict',
        'dependency_missing',
        'database',
      }.contains(code)
      ? code as String
      : null;

  Future<void> _scheduleRetry(SyncItem item, {String? errorCode}) async {
    if (!syncQueueBox.containsKey(item.id)) return;
    final nextRetryCount = item.retryCount + 1;
    final retryAt = _nextRetryAt(nextRetryCount);
    final updated = item.copyWith(
      retryCount: nextRetryCount,
      nextRetryAt: retryAt,
      lastErrorCode: errorCode,
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
    await EncryptedHive.box<ChatMessage>(boxName(chatMessageBoxName)).clear();
    await EncryptedHive.box<ChatConversation>(
      boxName(chatConversationBoxName),
    ).clear();
    await EncryptedHive.box<SafetyPlan>(boxName(safetyPlanBoxName)).clear();
    await userProfileBox.clear();
    await EncryptedHive.box<QuizAttempt>(boxName(quizAttemptBoxName)).clear();
    await EncryptedHive.box<SavedArticle>(boxName(savedArticleBoxName)).clear();
    await EncryptedHive.box<AppNotification>(
      boxName(appNotificationBoxName),
    ).clear();
    await EncryptedHive.box<SubscriptionStatus>(
      boxName(subscriptionStatusBoxName),
    ).clear();
    await syncQueueBox.clear();
    if (isBoxOpen(userPreferencesBoxName)) {
      await EncryptedHive.box<UserPreferences>(
        boxName(userPreferencesBoxName),
      ).clear();
    }
    if (isBoxOpen(userSettingsBoxName)) {
      await EncryptedHive.box<dynamic>(boxName(userSettingsBoxName)).clear();
    }
  }
}
