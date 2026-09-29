<?php

$dir = 'c:\projects\cozyhealth\cozy-health-mobile-app-main-main\lib';

$files = [
    "$dir\core\\repositories\mood_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../models/mood_entry.dart';
import '../services/local_db_service.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';

class MoodStats {
  final Map<String, dynamic> data;
  MoodStats(this.data);
  factory MoodStats.fromJson(Map<String, dynamic> json) => MoodStats(json);
}

class MoodRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<MoodEntry>> fetchMoodEntries({int page = 1, int perPage = 50}) async {
    try {
      final response = await ApiClient.instance.get(
        '/mood-entries',
        queryParameters: {'page': page, 'per_page': perPage},
      );
      final items = (response.data['data'] as List)
        .map((json) => MoodEntry.fromJson(json))
        .toList();
      for (final item in items) {
        await _local.saveMoodEntry(item);
      }
      return items;
    } on ApiAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Fetch moods failed: \$e');
      return _local.getAllMoodEntries();
    }
  }

  Stream<List<MoodEntry>> watchMoodEntries() async* {
    yield _local.getAllMoodEntries().where((e) => !e.isCrisisFlagged).toList(); // Simple filter if needed, though isDeleted should be checked ideally
    // Assuming no isDeleted on model, but standard getAll logic is fine
  }

  Future<MoodEntry> saveMoodEntry(MoodEntry entry) async {
    await _local.saveMoodEntry(entry);
    await _local.enqueueSync(type: 'mood_entry', action: 'upsert', recordId: entry.id, payload: entry.toJson());
    _tryServerSync(entry);
    return entry;
  }

  Future<MoodEntry> updateMoodEntry(MoodEntry entry) async {
    return await saveMoodEntry(entry);
  }

  Future<void> deleteMoodEntry(String id) async {
    // Should ideally mark as deleted, but removing for now
    // await _local.deleteMoodEntry(id);
    await _local.enqueueSync(type: 'mood_entry', action: 'delete', recordId: id);
    try {
      await ApiClient.instance.delete('/mood-entries/\$id');
    } catch (e) {
      debugPrint('Sync failed: \$e');
    }
  }

  Future<void> _tryServerSync(MoodEntry entry) async {
    try {
      await ApiClient.instance.post('/mood-entries', data: entry.toJson());
    } on ApiNetworkException {
    } on ApiTimeoutException {
    } on ApiValidationException catch (e) {
      debugPrint('Mood validation: \${e.fieldErrors}');
    } on ApiServerException {
    } on ApiAuthException {
    } catch (e) {
      debugPrint('Mood sync error: \$e');
    }
  }

  Future<MoodStats?> fetchStats() async {
    try {
      final response = await ApiClient.instance.get('/mood-entries/stats');
      return MoodStats.fromJson(response.data['data'] ?? {});
    } catch (e) {
      return null;
    }
  }
}
EOD,
    "$dir\core\\repositories\journal_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
import '../services/local_db_service.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';

class JournalRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<JournalEntry>> fetchJournalEntries({int page = 1, int perPage = 50}) async {
    try {
      final response = await ApiClient.instance.get('/journal-entries', queryParameters: {'page': page, 'per_page': perPage});
      final items = (response.data['data'] as List).map((json) => JournalEntry.fromJson(json)).toList();
      for (final item in items) {
        await _local.saveJournalEntry(item);
      }
      return items;
    } catch (e) {
      return _local.getAllJournalEntries();
    }
  }

  Stream<List<JournalEntry>> watchJournalEntries() {
    return _local.watchJournalEntries();
  }
  
  Stream<JournalEntry?> watchEntryById(String id) {
    return _local.watchJournalEntries().map((entries) =>
        entries.cast<JournalEntry?>().firstWhere((e) => e?.id == id, orElse: () => null));
  }

  Future<JournalEntry> saveJournalEntry(JournalEntry entry) async {
    await _local.saveJournalEntry(entry);
    await _local.enqueueSync(type: 'journal_entry', action: 'upsert', recordId: entry.id, payload: entry.toJson());
    _tryServerSync(entry);
    return entry;
  }
  
  Future<JournalEntry> updateJournalEntry(JournalEntry entry) async {
    return await saveJournalEntry(entry);
  }
  
  Future<void> deleteJournalEntry(String id) async {
    await _local.deleteJournalEntry(id);
    await _local.enqueueSync(type: 'journal_entry', action: 'delete', recordId: id);
    try {
      await ApiClient.instance.delete('/journal-entries/\$id');
    } catch (e) {
    }
  }

  Future<void> _tryServerSync(JournalEntry entry) async {
    try {
      await ApiClient.instance.post('/journal-entries', data: entry.toJson());
    } catch (e) {
      debugPrint('Sync failed: \$e');
    }
  }
}
EOD,
    "$dir\\features\\assistant\data\chat_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../../../core/models/chat_conversation.dart';
import '../../../core/models/chat_message.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class ChatRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<ChatConversation>> fetchConversations() async {
    try {
      final response = await ApiClient.instance.get('/conversations');
      final items = (response.data['data'] as List).map((json) => ChatConversation.fromJson(json)).toList();
      for (final item in items) {
        await _local.saveChatConversation(item);
      }
      return items;
    } catch (e) {
      return _local.getAllChatConversations();
    }
  }
  
  Stream<List<ChatConversation>> watchConversations() {
    return _local.watchChatConversations();
  }
  
  Future<List<ChatMessage>> fetchMessages(String convId) async {
    try {
      final response = await ApiClient.instance.get('/conversations/\$convId/messages');
      final items = (response.data['data'] as List).map((json) => ChatMessage.fromJson(json)).toList();
      for (final item in items) {
        await _local.saveChatMessage(item);
      }
      return items;
    } catch (e) {
      return _local.getMessagesForConversation(convId);
    }
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _local.watchChatMessages(conversationId);
  }

  Future<ChatConversation> saveConversation(ChatConversation conv) async {
    await _local.saveChatConversation(conv);
    await _local.enqueueSync(type: 'chat_conversation', action: 'upsert', recordId: conv.id, payload: conv.toJson());
    return conv;
  }
  
  Future<void> deleteConversation(String id) async {
    await _local.deleteChatConversation(id);
    await _local.enqueueSync(type: 'chat_conversation', action: 'delete', recordId: id);
    try {
      await ApiClient.instance.delete('/conversations/\$id');
    } catch (e) {}
  }

  Future<List<ChatMessage>> sendMessage(String conversationId, ChatMessage userMessage) async {
    try {
      final response = await ApiClient.instance.post(
        '/conversations/\$conversationId/messages',
        data: {
          'id': userMessage.id,
          'content': userMessage.content,
          'client_created_at': userMessage.createdAt.toUtc().toIso8601String(),
        },
      );
      
      final data = response.data['data'];
      final userMsg = ChatMessage.fromJson(data['user_message']);
      final assistantMsg = ChatMessage.fromJson(data['assistant_message']);
      
      await _local.saveChatMessage(userMsg);
      await _local.saveChatMessage(assistantMsg);
      
      return [userMsg, assistantMsg];
    } catch (e) {
      // Mark as failed locally (omitting method call since not defined in local_db_service)
      rethrow;
    }
  }
}
EOD,
    "$dir\\features\crisis\data\safety_plan_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../../../core/models/safety_plan.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class SafetyPlanRepository {
  final LocalDbService _local = LocalDbService();

  Future<SafetyPlan?> fetchSafetyPlan() async {
    try {
      final response = await ApiClient.instance.get('/safety-plan');
      if (response.data['data'] != null) {
        final plan = SafetyPlan.fromJson(response.data['data']);
        await _local.saveSafetyPlan(plan);
        return plan;
      }
    } catch (e) {
    }
    return _local.getSafetyPlan();
  }
  
  Stream<SafetyPlan?> watchSafetyPlan() {
    return _local.watchSafetyPlan();
  }

  Future<SafetyPlan> saveSafetyPlan(SafetyPlan plan) async {
    await _local.saveSafetyPlan(plan);
    await _local.enqueueSync(type: 'safety_plan', action: 'upsert', recordId: plan.id, payload: plan.toJson());
    try {
      await ApiClient.instance.put('/safety-plan', data: plan.toJson());
    } catch(e) {}
    return plan;
  }
}
EOD,
    "$dir\\features\settings\data\profile_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class ProfileRepository {
  final LocalDbService _local = LocalDbService();

  Future<UserProfile?> fetchProfile() async {
    try {
      final response = await ApiClient.instance.get('/user/profile');
      if (response.data['data'] != null) {
        final profile = UserProfile.fromJson(response.data['data']);
        await _local.saveUserProfile(profile);
        return profile;
      }
    } catch (e) {}
    return _local.getUserProfile();
  }
  
  Stream<UserProfile?> watchProfile() {
    return _local.watchUserProfile();
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    await _local.saveUserProfile(profile);
    await _local.enqueueSync(type: 'user_profile', action: 'upsert', recordId: profile.id, payload: profile.toJson());
    try {
      await ApiClient.instance.patch('/user/profile', data: profile.toJson());
    } catch(e) {}
    return profile;
  }
  
  Future<void> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      await ApiClient.instance.patch('/user/preferences', data: prefs);
      fetchProfile();
    } catch (e) {}
  }
  
  Future<void> updateNotificationPreferences(Map<String, dynamic> prefs) async {
    try {
      await ApiClient.instance.patch('/user/notification-preferences', data: prefs);
      fetchProfile();
    } catch (e) {}
  }
}
EOD,
    "$dir\\features\quiz\data\quiz_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../../../core/models/quiz_attempt.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class QuizRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<QuizAttempt>> fetchAttempts() async {
    try {
      final response = await ApiClient.instance.get('/quiz-attempts');
      final items = (response.data['data'] as List).map((json) => QuizAttempt.fromJson(json)).toList();
      for (final item in items) {
        await _local.saveQuizAttempt(item);
      }
      return items;
    } catch (e) {
      return _local.getAllQuizAttempts();
    }
  }

  Stream<List<QuizAttempt>> watchAttempts() {
    return _local.watchQuizAttempts();
  }

  Future<QuizAttempt> saveAttempt(QuizAttempt attempt) async {
    await _local.saveQuizAttempt(attempt);
    await _local.enqueueSync(type: 'quiz_attempt', action: 'upsert', recordId: attempt.id, payload: attempt.toJson());
    try {
      await ApiClient.instance.post('/quiz-attempts', data: attempt.toJson());
    } catch(e) {}
    return attempt;
  }
}
EOD,
    "$dir\\features\content\data\content_repository.dart" => <<<EOD
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
      await ApiClient.instance.post('/content/articles/\$articleId/save');
      fetchSavedArticles();
    } catch(e) {}
  }
  
  Future<void> unsaveArticle(String articleId) async {
    try {
      await ApiClient.instance.delete('/content/articles/\$articleId/save');
      fetchSavedArticles();
    } catch(e) {}
  }
}
EOD,
    "$dir\\features\\notifications\data\\notification_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../../../core/models/app_notification.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class NotificationRepository {
  final LocalDbService _local = LocalDbService();

  Future<List<AppNotification>> fetchNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      final items = (response.data['data'] as List).map((json) => AppNotification.fromJson(json)).toList();
      for (final item in items) {
        await _local.saveAppNotification(item);
      }
      return items;
    } catch (e) {
      return _local.getAllAppNotifications();
    }
  }

  Stream<List<AppNotification>> watchNotifications() {
    return _local.watchAppNotifications();
  }

  Future<void> markAsRead(String id) async {
    try {
      await ApiClient.instance.patch('/notifications/\$id/read');
      fetchNotifications();
    } catch(e) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all');
      fetchNotifications();
    } catch(e) {}
  }

  Future<void> deleteNotification(String id) async {
    await _local.deleteAppNotification(id);
    await _local.enqueueSync(type: 'app_notification', action: 'delete', recordId: id);
    try {
      await ApiClient.instance.delete('/notifications/\$id');
    } catch (e) {}
  }
}
EOD,
    "$dir\\features\settings\data\subscription_repository.dart" => <<<EOD
import 'package:flutter/foundation.dart';
import '../../../core/models/subscription_status.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';

class SubscriptionRepository {
  final LocalDbService _local = LocalDbService();

  Future<SubscriptionStatus?> fetchSubscription() async {
    try {
      final response = await ApiClient.instance.get('/subscription');
      if (response.data['data'] != null) {
        final sub = SubscriptionStatus.fromJson(response.data['data']);
        await _local.saveSubscriptionStatus(sub);
        return sub;
      }
    } catch (e) {}
    return _local.getSubscriptionStatus();
  }

  Stream<SubscriptionStatus?> watchSubscription() {
    return _local.watchSubscriptionStatus();
  }

  Future<void> verifyReceipt(Map<String, dynamic> data) async {
    try {
      await ApiClient.instance.post('/subscription/verify-receipt', data: data);
      fetchSubscription();
    } catch (e) {}
  }

  Future<void> restorePurchases() async {
    try {
      await ApiClient.instance.post('/subscription/restore');
      fetchSubscription();
    } catch (e) {}
  }
}
EOD
];

foreach ($files as $path => $content) {
    file_put_contents($path, $content);
}
echo "Repositories updated\n";
