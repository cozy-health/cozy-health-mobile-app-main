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

  Stream<UserProfile?> watchProfile() async* {
    final cached = _local.getUserProfile();
    if (cached != null) yield cached;
    yield* _local.watchUserProfile();
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    await _local.saveUserProfile(profile);
    await _local.enqueueSync(
      type: 'user_profile',
      action: 'upsert',
      recordId: profile.id,
      payload: profile.toJson(),
    );
    try {
      await ApiClient.instance.patch('/user/profile', data: profile.toJson());
    } catch (e) {}
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
      await ApiClient.instance.patch(
        '/user/notification-preferences',
        data: prefs,
      );
      fetchProfile();
    } catch (e) {}
  }

  Future<void> updateField(String key, dynamic value) async {
    final profile = _local.getUserProfile();
    if (profile == null) return;

    final updated = profile.copyWithField(key, value);
    await _local.saveUserProfile(updated);

    await _local.enqueueSync(
      type: 'user_profile',
      action: 'upsert',
      recordId: profile.id,
      payload: updated.toJson(),
    );

    try {
      await ApiClient.instance.patch(
        '/user/preferences',
        data: {_apiKey(key): value},
      );
    } catch (e) {
      debugPrint('Preference sync failed: $e');
    }
  }

  String _apiKey(String key) {
    return switch (key) {
      'accentColor' => 'accent_color',
      'reduceMotion' => 'reduce_motion',
      'highContrast' => 'high_contrast',
      'hapticsEnabled' => 'haptics_enabled',
      'textSize' => 'text_size',
      'showStats' => 'show_stats',
      'showUsername' => 'show_username',
      'notificationsMaster' => 'notifications_master',
      'dailyCheckinEnabled' => 'daily_checkin_enabled',
      'dailyCheckinTime' => 'daily_checkin_time',
      'journalReminderEnabled' => 'journal_reminder_enabled',
      'commentsNotifications' => 'comments_notifications',
      'achievementsNotifications' => 'achievements_notifications',
      'marketingNotifications' => 'marketing_notifications',
      _ => key,
    };
  }
}
