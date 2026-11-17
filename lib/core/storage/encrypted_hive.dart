import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
// Hive 2.2.3 is pinned: adapter bytes preserve fields omitted by API JSON.
// ignore: implementation_imports
import 'package:hive/src/binary/binary_writer_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Never falls back to plaintext or deletes data when a key cannot be read.
class EncryptedHive {
  static const _storage = FlutterSecureStorage();
  static const _reinstallBoxesKey = 'hive_reinstall_pending_boxes_v1';
  static Set<String> _reinstallBoxes = {};

  /// Retain secure storage, which can survive an iOS uninstall. A confirmed
  /// empty fresh installation may recreate boxes using their retained keys.
  static Future<void> prepareInstall({
    required bool markerSet,
    required bool hasLocalFiles,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!markerSet && !hasLocalFiles) {
      final values = await _storage.readAll();
      final names = values.entries
          .where(
            (entry) =>
                entry.key.startsWith('hive_migrated_v1_') && entry.value == '1',
          )
          .map((entry) => entry.key.substring('hive_migrated_v1_'.length))
          .toList();
      if (!await prefs.setStringList(_reinstallBoxesKey, names)) {
        throw StateError('Unable to persist reinstall storage status.');
      }
    }
    _reinstallBoxes = (prefs.getStringList(_reinstallBoxesKey) ?? []).toSet();
  }

  static final _opening = <String, Future<Box<dynamic>>>{};

  /// A successful server login can recover an entirely absent account cache
  /// left by an older reinstall build. Never repair a partially present cache.
  static Future<void> prepareAuthenticatedAccount(List<String> names) async {
    if (names.isEmpty) return;
    for (final name in names) {
      if (_opening.containsKey(name) ||
          await Hive.boxExists(name) ||
          await Hive.boxExists(physicalName(name))) {
        return;
      }
    }
    final retained = <String>[];
    for (final name in names) {
      if (await _storage.read(key: 'hive_migrated_v1_$name') == '1') {
        retained.add(name);
      }
    }
    if (retained.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = (prefs.getStringList(_reinstallBoxesKey) ?? []).toSet()
      ..addAll(retained);
    if (!await prefs.setStringList(_reinstallBoxesKey, pending.toList())) {
      throw StateError('Unable to persist account recovery status.');
    }
    _reinstallBoxes.addAll(retained);
  }

  static String physicalName(String name) => '${name.toLowerCase()}_aes256_v1';
  static bool isBoxOpen(String name) =>
      !_opening.containsKey(name.toLowerCase()) &&
      Hive.isBoxOpen(physicalName(name));
  static Box<T> box<T>(String name) {
    if (!isBoxOpen(name)) {
      throw StateError('Encrypted local storage is not ready.');
    }
    return Hive.box<T>(physicalName(name));
  }

  static Future<Box<T>> openBox<T>(String name) async {
    name = name.toLowerCase();
    final existing = _opening[name];
    if (existing != null) return await existing as Box<T>;
    if (isBoxOpen(name)) return box<T>(name);
    final opening = _open<T>(name);
    _opening[name] = opening;
    try {
      return await opening;
    } finally {
      _opening.remove(name);
    }
  }

  static Future<Box<T>> _open<T>(String name) async {
    final targetName = physicalName(name);
    final keyName = 'hive_key_v1_$name';
    final completeName = 'hive_migrated_v1_$name';
    final digestName = 'hive_key_digest_v1_$name';
    final sourceDigestName = 'hive_legacy_digest_v1_$name';
    final complete = await _storage.read(key: completeName) == '1';
    if (complete &&
        !await Hive.boxExists(targetName) &&
        !_reinstallBoxes.contains(name)) {
      throw StateError('Encrypted local data is missing. Recovery required.');
    }
    var encoded = await _storage.read(key: keyName);
    if (encoded == null) {
      if (await Hive.boxExists(targetName)) {
        throw StateError(
          'Local encryption key is unavailable. Data preserved.',
        );
      }
      encoded = base64Encode(Hive.generateSecureKey());
      await _storage.write(key: keyName, value: encoded);
      if (await _storage.read(key: keyName) != encoded) {
        throw StateError('Unable to persist local encryption key.');
      }
    }
    final key = base64Decode(encoded);
    if (key.length != 32) throw StateError('Invalid local encryption key.');
    final digest = sha256.convert(key).toString();
    final savedDigest = await _storage.read(key: digestName);
    if (savedDigest != digest) {
      if (await Hive.boxExists(targetName)) {
        throw StateError(
          'Local encryption key verification failed. Data preserved.',
        );
      }
      await _storage.write(key: digestName, value: digest);
      if (await _storage.read(key: digestName) != digest) {
        throw StateError('Unable to persist encryption key verification.');
      }
    }
    final cipher = HiveAesCipher(key);
    // Hive crash recovery can truncate unreadable records; never enable it here.
    var target = await _safeOpen<T>(targetName, cipher: cipher);
    try {
      if (!complete && await Hive.boxExists(name)) {
        final source = await _safeOpen<T>(name);
        final snapshot = source.toMap();
        // Until the completion marker is durable, the legacy box is authoritative.
        await target.clear();
        for (final entry in snapshot.entries) {
          await target.put(entry.key, _clone(entry.value) as T);
        }
        await target.flush();
        await target.close();
        target = await _safeOpen<T>(targetName, cipher: cipher);
        if (target.length != snapshot.length ||
            snapshot.entries.any(
              (entry) =>
                  !target.containsKey(entry.key) ||
                  sha256.convert(_bytes(target.get(entry.key))).toString() !=
                      sha256.convert(_bytes(entry.value)).toString(),
            )) {
          throw StateError('Local encryption migration verification failed.');
        }
        final sourceDigest = sha256.convert(_bytes(snapshot)).toString();
        await _storage.write(key: sourceDigestName, value: sourceDigest);
        if (await _storage.read(key: sourceDigestName) != sourceDigest) {
          throw StateError(
            'Unable to persist verified legacy snapshot status.',
          );
        }
      }
      if (!complete) {
        await target.flush();
        await _storage.write(key: completeName, value: '1');
        if (await _storage.read(key: completeName) != '1') {
          throw StateError('Unable to persist encryption migration status.');
        }
      }
      // Cleanup may be retried after a crash. A downgraded app may instead have
      // written new plaintext records: preserve both versions and stop in that case.
      if (await Hive.boxExists(name)) {
        final legacy = await _safeOpen<T>(name);
        final approved = await _storage.read(key: sourceDigestName);
        if (approved != sha256.convert(_bytes(legacy.toMap())).toString()) {
          throw StateError(
            'Legacy local data changed. Both versions preserved.',
          );
        }
        await Hive.deleteBoxFromDisk(name);
      }
      if (_reinstallBoxes.contains(name)) {
        // Retire the exception only after this box is durable. Other account
        // boxes may not be opened until the user logs in after a later restart.
        await target.flush();
        final prefs = await SharedPreferences.getInstance();
        final pending = (prefs.getStringList(_reinstallBoxesKey) ?? []).toSet()
          ..remove(name);
        if (!await prefs.setStringList(_reinstallBoxesKey, pending.toList())) {
          throw StateError('Unable to persist recreated local storage status.');
        }
        _reinstallBoxes.remove(name);
      }
      return target;
    } catch (_) {
      await target.close();
      rethrow;
    }
  }

  // Hive 2.2.3 reports a failed open through both its internal opening completer
  // and the returned future. Contain the duplicate error; surface one failure.
  static Future<Box<T>> _safeOpen<T>(String name, {HiveCipher? cipher}) {
    final result = Completer<Box<T>>();
    void fail(Object error, StackTrace stack) {
      if (!result.isCompleted) result.completeError(error, stack);
    }

    runZonedGuarded(() {
      Hive.openBox<T>(
        name,
        encryptionCipher: cipher,
        crashRecovery: false,
      ).then((box) {
        if (!result.isCompleted) result.complete(box);
      }, onError: fail);
    }, fail);
    return result.future;
  }

  static Uint8List _bytes(dynamic value) {
    final writer = BinaryWriterImpl(Hive)..write(value);
    return writer.toBytes();
  }

  static dynamic _clone(dynamic value) =>
      BinaryReaderImpl(_bytes(value), Hive).read();
}
