import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/storage/token_storage.dart';

class SplashService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  SplashService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<bool> hasStoredSession() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> validateStoredSession() async {
    try {
      await _apiClient.get(
        ApiConstants.me,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      return true;
    } on ApiAuthException {
      await _tokenStorage.clearToken();
      await LocalDbService.instance.clearAllUserData();
      return false;
    } catch (e) {
      debugPrint('Background /me validation failed (token kept): $e');
      return true;
    }
  }
}
