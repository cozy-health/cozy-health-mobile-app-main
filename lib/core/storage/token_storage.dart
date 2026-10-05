import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _tokenKey = 'cozy_health_access_token';

  static String? _sessionToken;
  static bool _sessionOnly = false;
  bool get isSessionOnly => _sessionOnly;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token, {bool stayLoggedIn = true}) async {
    _sessionToken = token;
    _sessionOnly = !stayLoggedIn;
    if (!stayLoggedIn) {
      await _storage.delete(key: _tokenKey);
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
    debugPrint('LOGIN_SAVED: token stored');
  }

  Future<String?> getToken() async {
    if (_sessionOnly) return _sessionToken;
    final result = await _storage.read(key: _tokenKey);
    debugPrint('TOKEN_READ: ${result != null}');
    return result;
  }

  Future<void> clearToken() async {
    _sessionToken = null;
    _sessionOnly = false;
    await _storage.delete(key: _tokenKey);
  }
}
