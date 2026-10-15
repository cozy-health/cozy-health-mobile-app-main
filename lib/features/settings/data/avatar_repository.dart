import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/guest_session_service.dart';

class AvatarRepository {
  static const endpoint = '/user/profile/avatar';
  static final presetIds = List.generate(
    24,
    (index) => 'open-peeps-${(index + 1).toString().padLeft(2, '0')}',
  );
  final _local = LocalDbService();

  Future<Uint8List?> cachedPhoto(UserProfile profile) async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    try {
      final box = await _local.settingsBox();
      if (scope != _local.boxName(LocalDbService.userSettingsBoxName) ||
          _local.getUserProfile()?.id != profile.id ||
          _local.getUserProfile()?.avatarRevision != profile.avatarRevision) {
        return null;
      }
      final cached = box.get('profile_avatar_bytes');
      if (cached is Map &&
          cached['revision'] == profile.avatarRevision &&
          cached['profile_id'] == profile.id &&
          cached['bytes'] is Uint8List) {
        return cached['bytes'] as Uint8List;
      }
      if (profile.avatarRevision == 0 ||
          Uri.tryParse(profile.avatarUrl ?? '')?.scheme != 'https') {
        return null;
      }
      // A separate unauthenticated client must never send app tokens to storage.
      final client = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          followRedirects: false,
        ),
      );
      try {
        final response = await client.get<List<int>>(
          profile.avatarUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = Uint8List.fromList(response.data ?? []);
        if (bytes.isEmpty ||
            bytes.length > 5 * 1024 * 1024 ||
            scope != _local.boxName(LocalDbService.userSettingsBoxName) ||
            _local.getUserProfile()?.avatarRevision != profile.avatarRevision ||
            _local.getUserProfile()?.id != profile.id) {
          return null;
        }
        await box.put('profile_avatar_bytes', {
          'revision': profile.avatarRevision,
          'profile_id': profile.id,
          'bytes': bytes,
        });
        return bytes;
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _apply(dynamic data, String scope) async {
    if (scope != _local.boxName(LocalDbService.userSettingsBoxName)) return;
    final current = _local.getUserProfile();
    if (current == null || data is! Map) return;
    final revision = (data['avatar_revision'] as num?)?.toInt() ?? 0;
    if (revision < current.avatarRevision) return;
    final value = data['avatar_url']?.toString();
    await _local.saveUserProfile(
      current.copyWith(
        avatarUrl: value,
        clearAvatarUrl: value == null || value.isEmpty,
        avatarRevision: revision,
      ),
    );
    if (scope == _local.boxName(LocalDbService.userSettingsBoxName) &&
        (value == null || value.startsWith('asset:'))) {
      await (await _local.settingsBox()).delete('profile_avatar_bytes');
    }
  }

  Future<void> refresh() async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    final response = await ApiClient.instance.get(endpoint);
    await _apply(response.data['data'], scope);
  }

  Future<void> save({
    String? presetId,
    Uint8List? photo,
    bool remove = false,
  }) async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    final owner = _local.activeUserId;
    if (await GuestSessionService().isGuestSession()) {
      throw StateError('Create an account before saving a profile picture.');
    }
    if (scope != _local.boxName(LocalDbService.userSettingsBoxName)) {
      throw StateError('Account changed');
    }
    final dynamic response;
    if (remove) {
      response = await ApiClient.instance.delete(
        endpoint,
        data: {'expected_user_id': owner},
      );
    } else if (presetId != null) {
      if (!presetIds.contains(presetId)) {
        throw const FormatException('Unknown avatar');
      }
      response = await ApiClient.instance.put(
        endpoint,
        data: {'preset_id': presetId, 'expected_user_id': owner},
      );
    } else {
      if (photo == null || photo.isEmpty || photo.length > 5 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 5 MB.');
      }
      response = await ApiClient.instance.post(
        endpoint,
        data: FormData.fromMap({
          'expected_user_id': owner,
          'photo': MultipartFile.fromBytes(photo, filename: 'avatar.jpg'),
        }),
      );
    }
    await _apply(response.data['data'], scope);
  }

  UserProfile? get profile => _local.getUserProfile();
}
