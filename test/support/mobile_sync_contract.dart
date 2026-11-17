import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/models/journal_entry.dart';
import 'package:cozy_health/core/models/safety_plan.dart';
import 'package:cozy_health/core/models/chat_conversation.dart';
import 'package:cozy_health/core/models/chat_message.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/user_preferences.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/models/saved_article.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:hive/hive.dart';

void registerSyncAdapters() {
  void register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter<T>(adapter);
    }
  }

  register(MoodEntryAdapter());
  register(JournalEntryAdapter());
  register(ChatConversationAdapter());
  register(ChatMessageAdapter());
  register(SafetyPlanAdapter());
  register(UserProfileAdapter());
  register(UserPreferencesAdapter());
  register(QuizAttemptAdapter());
  register(SavedArticleAdapter());
  register(AppNotificationAdapter());
  register(SubscriptionStatusAdapter());
}

/// Synthetic data only. Exported verbatim for backend persistence tests.
List<Map<String, dynamic>> mobileSyncOperations() {
  final now = DateTime.utc(2026, 10, 10, 12);
  String id(int number) =>
      '00000000-0000-4000-8000-${number.toString().padLeft(12, '0')}';
  final records = <String, Map<String, dynamic>>{
    'mood_entry': MoodEntry(
      id: id(1),
      mood: 'calm',
      intensity: 5,
      bodySensations: ['Relaxed'],
      triggers: ['Work'],
      note: 'Synthetic mood',
      createdAt: now,
      updatedAt: now,
    ).toJson(),
    'journal_entry': JournalEntry(
      id: id(2),
      type: 'free',
      body: 'Synthetic journal',
      wordCount: 2,
      createdAt: now,
      updatedAt: now,
    ).toJson(),
    'chat_conversation': ChatConversation(
      id: id(3),
      messageCount: 1,
      isArchived: false,
      createdAt: now,
      updatedAt: now,
    ).toJson(),
    'chat_message': ChatMessage(
      id: id(4),
      conversationId: id(3),
      role: 'user',
      content: 'Synthetic message',
      status: 'sent',
      isCrisisFlagged: false,
      createdAt: now,
    ).toJson(),
    'safety_plan': SafetyPlan(
      id: id(5),
      warningSigns: ['Synthetic warning'],
      isComplete: false,
      lastUpdatedAt: now,
    ).toJson(),
    // Auth creates a numeric placeholder; the server has a distinct profile UUID.
    'user_profile': UserProfile(
      id: '42',
      name: 'Synthetic user',
      email: 'synthetic@example.test',
      updatedAt: now,
    ).toJson(),
    'user_preferences': {
      'id': id(7),
      ...UserPreferences(
        focusAreas: ['Sleep'],
        currentChallenges: ['Work'],
        checkInFrequency: 'Daily',
        completedAt: now,
        skipped: false,
      ).toJson(),
    },
    'quiz_attempt': QuizAttempt(
      id: id(8),
      quizId: 'synthetic-quiz',
      quizSlug: 'synthetic-quiz',
      quizTitle: 'Synthetic quiz',
      answers: [1, 2],
      score: 3,
      interpretation: 'Synthetic result',
      isCrisisFlagged: false,
      completedAt: now,
    ).toJson(),
    // Legacy bookmarks lack slug/category/read time, and saved_UUID exceeds 36 chars.
    'saved_article': SavedArticle(
      id: 'saved_${id(9)}',
      articleId: id(9),
      title: 'Synthetic article',
      excerpt: 'Synthetic excerpt',
      imageUrl: '',
      savedAt: now,
    ).toJson(),
    'app_notification': AppNotification(
      id: id(10),
      title: 'Synthetic notification',
      body: 'Synthetic body',
      type: 'system',
      read: false,
      createdAt: now,
    ).toJson(),
    'subscription': SubscriptionStatus(
      id: 'sub_123456789',
      isActive: false,
      tier: 'free',
      cancelAtPeriodEnd: false,
    ).toJson(),
  };
  return [
    for (final entry in records.entries)
      {
        'client_operation_id': 'contract-${entry.key}',
        'type': entry.key,
        'action': 'upsert',
        'data': entry.value,
      },
  ];
}
