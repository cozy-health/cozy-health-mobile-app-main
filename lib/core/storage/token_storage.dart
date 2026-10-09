import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class TokenStorage {
  static const String _tokenKey = 'cozy_health_access_token';

  static String? _sessionToken;
  static String? _sessionRefresh;
  static bool _sessionOnly = false;
  bool get isSessionOnly => _sessionOnly;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveRefreshToken(String? value) async {
    _sessionRefresh = value;
    if (_sessionOnly || value == null) {
      await _storage.delete(key: 'cozy_health_refresh_token');
    } else {
      await _storage.write(key: 'cozy_health_refresh_token', value: value);
    }
  }

  Future<String?> getRefreshToken() async => _sessionOnly
      ? _sessionRefresh
      : await _storage.read(key: 'cozy_health_refresh_token');

  Future<String> deviceId() async {
    final stored = await _storage.read(key: 'cozy_health_device_id');
    if (stored != null) return stored;
    final id = const Uuid().v4();
    await _storage.write(key: 'cozy_health_device_id', value: id);
    return id;
  }

  Future<void> recordActivity([DateTime? now]) => _storage.write(
    key: 'cozy_health_last_activity',
    value: (now ?? DateTime.now()).toUtc().toIso8601String(),
  );

  Future<bool> inactivityExpired({
    required bool sensitive,
    DateTime? now,
  }) async {
    final value = await _storage.read(key: 'cozy_health_last_activity');
    final last = DateTime.tryParse(value ?? '');
    // Existing sessions acquire a baseline without being silently invalidated.
    if (last == null) {
      await recordActivity(now);
      return false;
    }
    final age = (now ?? DateTime.now()).toUtc().difference(last);
    return age.isNegative ||
        age >=
            (sensitive ? const Duration(minutes: 5) : const Duration(days: 30));
  }

  Future<void> saveToken(String token, {bool stayLoggedIn = true}) async {
    _sessionToken = token;
    _sessionOnly = !stayLoggedIn;
    if (!stayLoggedIn) {
      await _storage.delete(key: _tokenKey);
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_sessionOnly) return _sessionToken;
    final result = await _storage.read(key: _tokenKey);
    return result;
  }

  Future<void> clearToken() async {
    _sessionToken = null;
    _sessionOnly = false;
    _sessionRefresh = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: 'cozy_health_refresh_token');
    await _storage.delete(key: 'cozy_health_last_activity');
  }
}
