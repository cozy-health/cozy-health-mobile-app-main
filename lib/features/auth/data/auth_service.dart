import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService({
    ApiClient? apiClient,
    TokenStorage? tokenStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.login,
      withAuth: false,
      body: {
        'email': email,
        'password': password,
      },
    );

    final token = response['access_token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> register({
    required String firstname,
    required String lastname,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.register,
      withAuth: false,
      body: {
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'password': password,
      },
    );

    final token = response['access_token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _tokenStorage.saveToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> me() async {
    return _apiClient.get(ApiConstants.me);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}