import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Random server proof only: public device IDs and security answers never go here.
class DeviceProofStorage {
  DeviceProofStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
              synchronizable: false,
            ),
          );
  final FlutterSecureStorage _storage;
  static final _proofPattern = RegExp(r'^[a-f0-9]{64}$');
  String _key(String identity) =>
      'cozy.signin.user.v1.${sha256.convert(utf8.encode(identity))}';
  String emailHint(String email) => 'email:${email.trim().toLowerCase()}';

  Future<Map<String, dynamic>?> _record(String accountId) async {
    try {
      final value = await _storage.read(key: _key('account:$accountId'));
      if (value == null) return null;
      final data = jsonDecode(value);
      if (data is! Map ||
          data['account_id'] != accountId ||
          data['proof'] is! String ||
          !_proofPattern.hasMatch(data['proof'] as String)) {
        return null;
      }
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }

  Future<String?> forAccount(String? accountId) async => accountId == null
      ? null
      : (await _record(accountId))?['proof'] as String?;
  Future<String?> forHint(String hint) async {
    try {
      final accountId = await _storage.read(key: _key('hint:$hint'));
      return accountId == null ? null : await forAccount(accountId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> forEmail(String email) => forHint(emailHint(email));

  Future<bool> remember({
    required String accountId,
    required String email,
    required String proof,
    String? identityHint,
  }) async {
    if (accountId.isEmpty ||
        !email.contains('@') ||
        !_proofPattern.hasMatch(proof)) {
      return false;
    }
    try {
      final old = await _record(accountId);
      final previousHints = old?['hints'];
      final oldHints = (previousHints is List ? previousHints : const [])
          .whereType<String>();
      final hints = {
        ...oldHints,
        emailHint(email),
        if (identityHint != null) identityHint,
      }.toList();
      final retained = hints
          .skip(hints.length > 8 ? hints.length - 8 : 0)
          .toList();
      await _storage.write(
        key: _key('account:$accountId'),
        value: jsonEncode({
          'account_id': accountId,
          'proof': proof,
          'hints': retained,
        }),
      );
      for (final hint in retained) {
        await _storage.write(key: _key('hint:$hint'), value: accountId);
      }
      for (final hint in hints.where((hint) => !retained.contains(hint))) {
        await _storage.delete(key: _key('hint:$hint'));
      }
      return true;
    } catch (_) {
      return false;
    } // Sign-in can work without remembering a device.
  }

  Future<void> forgetAccount(String accountId) async {
    final record = await _record(accountId);
    final hints = record?['hints'];
    if (hints is List) {
      for (final hint in hints.whereType<String>()) {
        final key = _key('hint:$hint');
        if (await _storage.read(key: key) == accountId) {
          await _storage.delete(key: key);
        }
      }
    }
    await _storage.delete(key: _key('account:$accountId'));
  }
}
