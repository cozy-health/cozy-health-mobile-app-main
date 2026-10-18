import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class TokenStorage {
  static final _sessionClearing = StreamController<void>.broadcast(sync: true);
  static Stream<void> get sessionClearing => _sessionClearing.stream;
  // Announces a completed token change without exposing the token itself.
  static final _sessionChanges = StreamController<void>.broadcast(sync: true);
  static Stream<void> get sessionChanges => _sessionChanges.stream;
  static Future<void> Function()? beforeClear;
  static const String _tokenKey = 'cozy_health_access_token';

  static String? _sessionToken;
  static String? _sessionRefresh;
  static bool _sessionOnly = false;
  static bool _signedOut = false;
  static int _generation = 0;
  static int get generation => _generation;
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

  Future<String?> getRefreshToken() async => _signedOut
      ? null
      : _sessionOnly
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
    _generation++;
    _signedOut = false;
    _sessionToken = token;
    _sessionOnly = !stayLoggedIn;
    if (!stayLoggedIn) {
      await _storage.delete(key: _tokenKey);
      _sessionChanges.add(null);
      return;
    }
    await _storage.write(key: _tokenKey, value: token);
    _sessionChanges.add(null);
  }

  Future<String?> getToken() async {
    if (_signedOut) return null;
    if (_sessionOnly) return _sessionToken;
    final result = await _storage.read(key: _tokenKey);
    return result;
  }

  Future<void> clearToken() async {
    _generation++;
    _signedOut = true;
    _sessionClearing.add(null);
    // Cleanup must capture its owner immediately, but never delay local logout.
    final cleanup = beforeClear?.call();
    if (cleanup != null) unawaited(cleanup.catchError((Object _) {}));
    _sessionToken = null;
    _sessionOnly = false;
    _sessionRefresh = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: 'cozy_health_refresh_token');
    await _storage.delete(key: 'cozy_health_last_activity');
    _sessionChanges.add(null);
  }
}
