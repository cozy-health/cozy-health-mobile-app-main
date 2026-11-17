import '../storage/token_storage.dart';

class AuthTokenService {
  static final _storage = TokenStorage();

  static Future<void> saveToken(String token) async {
    await _storage.saveToken(token);
  }

  static Future<String?> getToken() async {
    return await _storage.getToken();
  }

  static Future<void> clearToken() async {
    await _storage.clearToken();
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
