import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/guest_session_service.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/restore_service.dart';
import '../../../core/services/user_data_fetcher.dart';
import '../../../core/services/device_integrity_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../settings/data/profile_repository.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
    : _apiClient = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool stayLoggedIn = false,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      withAuth: false,
      body: {
        'email': email,
        'password': password,
        'device_id': await _tokenStorage.deviceId(),
        'device_name': defaultTargetPlatform.name,
      },
    );

    final data = _payload(responseMap(response));
    await _acceptSession(data, stayLoggedIn: stayLoggedIn);

    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogle(
    String idToken, {
    bool stayLoggedIn = true,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.googleLogin,
      withAuth: false,
      body: {
        'id_token': idToken,
        'device_name': defaultTargetPlatform.name,
        'device_id': await _tokenStorage.deviceId(),
      },
    );
    final data = _payload(responseMap(response));
    await _acceptSession(data, stayLoggedIn: stayLoggedIn);

    return data;
  }

  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    String? authorizationCode,
    String? fullName,
    String? email,
    bool stayLoggedIn = true,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.appleLogin,
      withAuth: false,
      body: {
        'identity_token': identityToken,
        if (authorizationCode != null && authorizationCode.isNotEmpty)
          'authorization_code': authorizationCode,
        if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
        'device_name': defaultTargetPlatform.name,
        'device_id': await _tokenStorage.deviceId(),
      },
    );
    final data = _payload(responseMap(response));
    await _acceptSession(data, stayLoggedIn: stayLoggedIn);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final name = '$firstname $lastname'.trim();
    final response = await _apiClient.post(
      ApiConstants.register,
      withAuth: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
        'device_id': await _tokenStorage.deviceId(),
        'device_name': defaultTargetPlatform.name,
      },
    );

    final data = _payload(responseMap(response));
    await _acceptSession(data, stayLoggedIn: true, registration: true);

    return data;
  }

  Future<Map<String, dynamic>> me() async {
    return _payload(responseMap(await _apiClient.get(ApiConstants.me)));
  }

  Future<bool> resumeStoredSession() async {
    final profile = await me();
    final userId = profile['user_id']?.toString();
    if (userId == null) {
      throw const FormatException('Missing account identity.');
    }
    final local = LocalDbService();
    local.syncPaused = true;
    try {
      await local.waitForSyncIdle();
      await local.activateAccount(userId, email: profile['email']?.toString());
      await GuestSessionService().exitGuestSession();
      return await RestoreService.prepare(userId);
    } finally {
      local.syncPaused = false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (e) {
      debugPrint('Logout API failed: details withheld.');
    } finally {
      await _tokenStorage.clearToken();
      await GuestSessionService().exitGuestSession();
      await LocalDbService.instance.activateGuest();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return _payload(
      responseMap(
        await _apiClient.post(
          ApiConstants.forgotPassword,
          withAuth: false,
          body: {'email': email},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return _payload(
      responseMap(
        await _apiClient.post(
          ApiConstants.resetPassword,
          withAuth: false,
          body: {'email': email, 'token': otp, 'password': newPassword},
        ),
      ),
    );
  }

  Map<String, dynamic> _payload(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : response;
  }

  Future<void> _cacheUserProfile(dynamic user) async {
    if (user is! Map) return;

    final json = Map<String, dynamic>.from(user);
    final id = json['id']?.toString();
    final email = json['email']?.toString();
    final name = json['name']?.toString();

    if (id == null || email == null || name == null || name.isEmpty) return;

    final cached = LocalDbService.instance.getUserProfile();
    if (cached != null) return;

    await LocalDbService.instance.saveUserProfile(
      UserProfile(
        id: id,
        name: name,
        email: email,
        username: json['username']?.toString(),
        avatarUrl:
            json['avatar_url']?.toString() ?? json['avatar_path']?.toString(),
        updatedAt:
            DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
            DateTime.now(),
      ),
    );
    await (await LocalDbService().settingsBox()).put(
      'auth_profile_placeholder',
      true,
    );
  }

  Future<void> _acceptSession(
    Map<String, dynamic> data, {
    required bool stayLoggedIn,
    bool registration = false,
  }) async {
    final token = data['token']?.toString();
    final user = data['user'];
    if (token == null || token.isEmpty || user is! Map || user['id'] == null) {
      throw const FormatException('Missing session identity.');
    }
    final local = LocalDbService();
    local.syncPaused = true;
    try {
      await local.waitForSyncIdle();
      await local.activateAccount(
        user['id'].toString(),
        email: user['email']?.toString(),
        registration: registration,
      );
      await _tokenStorage.saveToken(token, stayLoggedIn: stayLoggedIn);
      await _tokenStorage.saveRefreshToken(data['refresh_token']?.toString());
      await _tokenStorage.recordActivity();
      unawaited(DeviceIntegrityService.instance.reportIfDetected());
      await GuestSessionService().exitGuestSession();
      await (await local.settingsBox()).put(
        'device_user_id',
        user['id'].toString(),
      );
      await _cacheUserProfile(user);
      final restore = await RestoreService.prepare(
        user['id'].toString(),
        registration: registration,
      );
      if (!restore) await ProfileRepository().fetchProfile();
    } finally {
      local.syncPaused = false;
    }
    if (!await RestoreService.required) _syncUserDataInBackground();
  }

  void _syncUserDataInBackground() {
    unawaited(
      UserDataFetcher().fetchAll().then((_) {
        debugPrint('Background data sync complete');
      }),
    );
  }
}
