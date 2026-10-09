import '../storage/encrypted_hive.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import '../api/auth_token_service.dart';

/// Derived API data only; never replaces or clears offline mood records.
class EndpointCache {
  EndpointCache({DateTime Function()? now}) : now = now ?? DateTime.now;
  final DateTime Function() now;
  static const boxName = 'endpoint_cache';
  static Future<Box<String>>? _opening;

  Future<Box<String>> _box() async {
    if (EncryptedHive.isBoxOpen(boxName)) {
      return EncryptedHive.box<String>(boxName);
    }
    try {
      return await (_opening ??= EncryptedHive.openBox<String>(boxName));
    } finally {
      _opening = null;
    }
  }

  Future<String?> owner() async {
    final token = await AuthTokenService.getToken();
    // Sanctum tokens contain a unique, non-secret token ID before the separator.
    if (token == null || !token.contains('|')) return null;
    return token.split('|').first;
  }

  Future<Map<String, dynamic>?> read(
    String key, {
    bool allowStale = false,
  }) async {
    final scope = await owner();
    if (scope == null) return null;
    final raw = (await _box()).get('$scope:$key');
    if (raw == null) return null;
    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      final age = now().difference(
        DateTime.parse(record['cached_at'] as String),
      );
      if (!allowStale &&
          (age.isNegative || age >= const Duration(minutes: 5))) {
        return null;
      }
      return Map<String, dynamic>.from(record['data'] as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String key,
    Map<String, dynamic> data,
    String? scope,
  ) async {
    if (scope == null || scope != await owner()) return;
    await (await _box()).put(
      '$scope:$key',
      jsonEncode({'cached_at': now().toUtc().toIso8601String(), 'data': data}),
    );
  }
}
