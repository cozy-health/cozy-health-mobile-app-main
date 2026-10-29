import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );
  // Every instance addresses the same keychain keys. Ordering must therefore
  // span instances, including a logout racing an already-started native write.
  static Future<void>? _writes;
  static Future<void> _ordered(Future<void> Function() operation) {
    final previous = _writes;
    final next = previous == null
        ? Future<void>.sync(operation)
        : previous.then((_) => operation());
    final settled = next.catchError((Object _) {});
    _writes = settled;
    unawaited(
      settled.then((_) {
        if (identical(_writes, settled)) _writes = null;
      }),
    );
    return next;
  }

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
  // Used only to revoke the session captured at the instant logout starts.
  // Authenticated requests still read storage and recheck the generation.
  String? get activeToken => _signedOut ? null : _sessionToken;
  final FlutterSecureStorage _storage;

  Future<void> saveRefreshToken(
    String? value, {
    required int expectedGeneration,
  }) async {
    if (_signedOut || expectedGeneration != _generation) return;
    final generation = _generation;
    _sessionRefresh = value;
    final sessionOnly = _sessionOnly;
    await _ordered(() async {
      if (generation != _generation) return;
      if (sessionOnly || value == null) {
        await _storage.delete(key: 'cozy_health_refresh_token');
      } else {
        await _storage.write(key: 'cozy_health_refresh_token', value: value);
      }
    });
  }

  Future<String?> getRefreshToken() async {
    if (_signedOut) return null;
    final generation = _generation;
    if (_sessionOnly) return _sessionRefresh;
    final pending = _writes;
    if (pending != null) await pending;
    if (generation != _generation || _signedOut) return null;
    final value = await _storage.read(key: 'cozy_health_refresh_token');
    return generation == _generation && !_signedOut ? value : null;
  }

  Future<String> deviceId() async {
    final stored = await _storage.read(key: 'cozy_health_device_id');
    if (stored != null) return stored;
    final id = const Uuid().v4();
    await _storage.write(key: 'cozy_health_device_id', value: id);
    return id;
  }

  Future<void> recordActivity([DateTime? now]) {
    final generation = _generation;
    return _ordered(() async {
      if (generation != _generation) return;
      await _storage.write(
        key: 'cozy_health_last_activity',
        value: (now ?? DateTime.now()).toUtc().toIso8601String(),
      );
    });
  }

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
    await saveSession(token, stayLoggedIn: stayLoggedIn);
  }

  /// Access and refresh credentials belong to one generation. Callers must not
  /// install the refresh credential in a separate, later account's session.
  Future<int> saveSession(
    String token, {
    String? refreshToken,
    bool stayLoggedIn = true,
  }) async {
    final generation = ++_generation;
    _signedOut = false;
    _sessionToken = token;
    _sessionOnly = !stayLoggedIn;
    _sessionRefresh = refreshToken;
    await _ordered(() async {
      if (generation != _generation) return;
      await _storage.delete(key: 'cozy_health_refresh_token');
      if (!stayLoggedIn) {
        await _storage.delete(key: _tokenKey);
      } else {
        await _storage.write(key: _tokenKey, value: token);
      }
      if (generation != _generation) return;
      if (stayLoggedIn && refreshToken != null) {
        await _storage.write(
          key: 'cozy_health_refresh_token',
          value: refreshToken,
        );
      }
    });
    if (generation == _generation) _sessionChanges.add(null);
    return generation;
  }

  Future<String?> getToken() async {
    if (_signedOut) return null;
    if (_sessionOnly) return _sessionToken;
    final generation = _generation;
    final pending = _writes;
    if (pending != null) await pending;
    if (generation != _generation || _signedOut) return null;
    final result = await _storage.read(key: _tokenKey);
    if (generation != _generation || _signedOut) return null;
    _sessionToken = result;
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
    await _ordered(() async {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: 'cozy_health_refresh_token');
      await _storage.delete(key: 'cozy_health_last_activity');
    });
    _sessionChanges.add(null);
  }
}
