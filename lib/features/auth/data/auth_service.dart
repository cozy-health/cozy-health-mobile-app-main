import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/response_data.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/services/user_data_fetcher.dart';
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
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      withAuth: false,
      body: {'email': email, 'password': password},
    );

    final data = _payload(responseMap(response));
    final token = data['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
    }
    await _cacheUserProfile(data['user']);
    await ProfileRepository().fetchProfile();
    _syncUserDataInBackground();

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
      },
    );

    final data = _payload(responseMap(response));
    final token = data['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
    }
    await _cacheUserProfile(data['user']);
    await ProfileRepository().fetchProfile();
    _syncUserDataInBackground();

    return data;
  }

  Future<Map<String, dynamic>> me() async {
    return _payload(responseMap(await _apiClient.get(ApiConstants.me)));
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (e) {
      debugPrint('Logout API failed: $e');
    } finally {
      await _tokenStorage.clearToken();
      await LocalDbService.instance.clearAllUserData();
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
  }

  void _syncUserDataInBackground() {
    unawaited(
      UserDataFetcher().fetchAll().then((_) {
        debugPrint('Background data sync complete');
      }),
    );
  }
}
