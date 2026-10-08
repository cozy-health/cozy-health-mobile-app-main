import '../models/mood_entry.dart';
import '../models/journal_entry.dart';
import '../models/user_profile.dart';
import '../models/safety_plan.dart';
import '../models/quiz_attempt.dart';
import '../models/saved_article.dart';
import '../models/app_notification.dart';
import '../models/chat_conversation.dart';
import 'local_db_service.dart';

class UserDataMerge {
  final _local = LocalDbService();
  static DateTime? timestamp(Map<String, dynamic> row) {
    for (final key in [
      'client_updated_at',
      'last_updated_at',
      'updated_at',
      'read_at',
      'completed_at',
      'saved_at',
      'client_created_at',
      'created_at',
    ]) {
      final value = DateTime.tryParse(row[key]?.toString() ?? '');
      if (value != null) return value.toUtc();
    }
    return null;
  }

  Map<String, dynamic>? localRow(String type, String id) {
    final dynamic entry = switch (type) {
      'mood_entry' => _local.moodBox.get(id),
      'journal_entry' => _local.journalBox.get(id),
      'user_profile' => _local.getUserProfile(),
      'safety_plan' => _local.getSafetyPlan(),
      'quiz_attempt' => _local.quizAttemptBox.get(id),
      'saved_article' => _local.savedArticleBox.get(id),
      'app_notification' => _local.appNotificationBox.get(id),
      'chat_conversation' => _local.chatConversationBox.get(id),
      _ => throw ArgumentError('Unknown cache domain'),
    };
    return entry == null
        ? null
        : Map<String, dynamic>.from(entry.toJson() as Map);
  }

  Future<void> apply(
    String type,
    Map<String, dynamic> incoming, {
    String? owner,
    bool Function()? isActive,
  }) async {
    incoming = {
      ...incoming,
      if (incoming['client_created_at'] == null &&
          incoming['created_at'] != null)
        'client_created_at': incoming['created_at'],
      if (incoming['client_updated_at'] == null &&
          (incoming['updated_at'] ?? incoming['last_updated_at']) != null)
        'client_updated_at':
            incoming['updated_at'] ?? incoming['last_updated_at'],
    };
    final settings = await _local.settingsBox();
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    owner ??= settings.get('device_user_id')?.toString();
    bool active() =>
        (isActive?.call() ?? true) &&
        scope == _local.boxName(LocalDbService.userSettingsBoxName) &&
        (owner == null || settings.get('device_user_id')?.toString() == owner);
    if (!active()) return;
    if (owner != null &&
        incoming['user_id'] != null &&
        incoming['user_id'].toString() != owner) {
      throw const FormatException('Account mismatch');
    }
    final id =
        (type == 'saved_article'
                ? incoming['article_id'] ?? incoming['id']
                : incoming['id'])
            ?.toString();
    if (id == null || id.isEmpty) {
      throw const FormatException('Missing record identifier');
    }
    var local = localRow(type, id);
    final localId = local?['id']?.toString() ?? id;
    final pending = _local.pendingItems
        .where(
          (item) =>
              item.type == type &&
              (item.recordId == id || item.recordId == localId),
        )
        .toList();
    final placeholder =
        type == 'user_profile' &&
        settings.get('auth_profile_placeholder') == true &&
        pending.isEmpty;
    if (placeholder) {
      local = null;
    }
    // A pending delete is a tombstone: background downloads cannot resurrect it.
    if (pending.any((item) => item.action == 'delete')) return;
    final localTime = local == null ? null : timestamp(local);
    final remoteTime = timestamp(incoming);
    final keepLocal =
        local != null &&
        (local['is_draft'] == true ||
            (localTime != null &&
                (remoteTime == null || localTime.isAfter(remoteTime))) ||
            (pending.isNotEmpty &&
                (remoteTime == null ||
                    (localTime != null &&
                        localTime.isAtSameMomentAs(remoteTime)))));
    if (keepLocal) {
      final value = {...incoming, ...local, 'id': incoming['id']};
      // Profile endpoint IDs differ from auth user IDs; migrate the placeholder
      // to the canonical profile ID without losing local edits or their intent.
      if (localId != id && type == 'user_profile') {
        for (final item in pending) {
          await _local.syncQueueBox.delete(item.id);
        }
        if (!active()) return;
        await _write(type, value);
      }
      if (local['is_draft'] != true && (pending.isEmpty || localId != id)) {
        if (!active()) return;
        await _local.enqueueSync(
          type: type,
          action: 'upsert',
          recordId: id,
          payload: value,
        );
      }
      return;
    }
    for (final item in pending) {
      await _local.syncQueueBox.delete(item.id);
    }
    if (!active()) return;
    // Recheck after asynchronous queue writes so a newly edited local record wins.
    final latest = localRow(type, id);
    final latestTime = latest == null ? null : timestamp(latest);
    if (!placeholder &&
        latest != null &&
        latestTime != localTime &&
        latestTime != null &&
        (remoteTime == null || latestTime.isAfter(remoteTime))) {
      return;
    }
    await _write(type, {...?local, ...incoming});
    if (type == 'user_profile') {
      await settings.put('auth_profile_placeholder', false);
    }
  }

  Future<void> _write(String type, Map<String, dynamic> value) async {
    switch (type) {
      case 'mood_entry':
        await _local.saveMoodEntry(MoodEntry.fromJson(value));
      case 'journal_entry':
        await _local.saveJournalEntry(JournalEntry.fromJson(value));
      case 'user_profile':
        await _local.saveUserProfile(UserProfile.fromJson(value));
      case 'safety_plan':
        await _local.saveSafetyPlan(SafetyPlan.fromJson(value));
      case 'quiz_attempt':
        await _local.saveQuizAttempt(QuizAttempt.fromJson(value));
      case 'saved_article':
        await _local.saveSavedArticle(SavedArticle.fromJson(value));
      case 'app_notification':
        await _local.saveNotification(AppNotification.fromJson(value));
      case 'chat_conversation':
        await _local.saveChatConversation(ChatConversation.fromJson(value));
    }
  }
}
