import '../../../core/services/user_data_merge.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ProfileRepository {
  final LocalDbService _local = LocalDbService();

  Map<String, dynamic>? _extractMapData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      if (!data.containsKey('data')) return data;
    }
    debugPrint('Unexpected profile response shape: ${data.runtimeType}');
    return null;
  }

  Future<UserProfile?> fetchProfile() async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final response = await ApiClient.instance.get(ApiConstants.me);
      final data = _extractMapData(response.data);
      if (data != null) {
        await UserDataMerge().apply(
          'user_profile',
          data,
          isActive: () =>
              scope == _local.boxName(LocalDbService.userSettingsBoxName),
        );
        return _local.getUserProfile();
      }
    } catch (e) {
      debugPrint('Fetch profile failed: details withheld.');
    }
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

  Future<bool> updatePreferences(Map<String, dynamic> prefs) async {
    try {
      await ApiClient.instance.patch('/user/preferences', data: prefs);
      await fetchProfile();
      return true;
    } catch (e) {
      debugPrint('Update preferences failed: details withheld.');
      return false;
    }
  }

  Future<bool> updateNotificationPreferences(Map<String, dynamic> prefs) async {
    try {
      await ApiClient.instance.patch(
        '/user/notification-preferences',
        data: prefs,
      );
      await fetchProfile();
      return true;
    } catch (e) {
      debugPrint('Update notification preferences failed: details withheld.');
      return false;
    }
  }

  Future<void> updateField(String key, dynamic value) async {
    var profile = _local.getUserProfile();

    if (profile == null) {
      profile = UserProfile(
        id: const Uuid().v4(),
        name: '',
        email: '',
        updatedAt: DateTime.now(),
      );
      await _local.saveUserProfile(profile);
    }

    final updated = profile.copyWithField(key, value);
    await _local.saveUserProfile(updated);

    await _local.enqueueSync(
      type: 'user_profile',
      action: 'upsert',
      recordId: profile.id,
      payload: updated.toJson(),
    );
    Future.microtask(() => _local.processSyncQueue());
  }
}
