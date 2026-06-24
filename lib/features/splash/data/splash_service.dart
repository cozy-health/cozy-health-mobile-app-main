import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class SplashService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  SplashService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<bool> hasValidSession() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await _apiClient.get(ApiConstants.me);
      return true;
    } catch (_) {
      await _tokenStorage.clearToken();
      return false;
    }
  }
}