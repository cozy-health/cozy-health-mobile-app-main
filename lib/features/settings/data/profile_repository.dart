import 'package:flutter/foundation.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ProfileRepository {
  final LocalDbService _local = LocalDbService();

  Future<UserProfile?> fetchProfile() async {
    try {
      final response = await ApiClient.instance.get(ApiConstants.me);
      if (response.data['data'] != null) {
        final profile = UserProfile.fromJson(response.data['data']);
        await _local.saveUserProfile(profile);
        return profile;
      }
    } catch (e) {}
    return _local.getUserProfile();
  }

  Stream<UserProfile?> watchProfile() async* {
    try {
      final cached = _local.getUserProfile();
      if (cached != null) yield cached;
    } catch (_) {
      // Hive may be unavailable in lightweight widget tests.
    }

    try {
      yield* _local.watchUserProfile();
    } catch (_) {
      // Keep app startup resilient if Hive has not been initialized yet.
    }
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    await _local.saveUserProfile(profile);
    await _local.enqueueSync(
      type: 'user_profile',
      action: 'upsert',
      recordId: profile.id,
      payload: profile.toJson(),
    );
    _local.processSyncQueue();
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
    _local.processSyncQueue();
  }
}
