import 'dart:async';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class DelayedStorage extends FlutterSecureStorage {
  final values = <String, String>{};
  final entered = Completer<void>();
  final release = Completer<void>();
  bool delayNext = true;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (key == 'cozy_health_access_token' && delayNext) {
      delayNext = false;
      entered.complete();
      await release.future;
    }
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  test(
    'delayed account installation cannot attach its refresh to a newer account',
    () async {
      final disk = DelayedStorage();
      final storage = TokenStorage(storage: disk);
      final first = storage.saveSession('account-a', refreshToken: 'refresh-a');
      await disk.entered.future;
      final second = storage.saveSession(
        'account-b',
        refreshToken: 'refresh-b',
      );
      disk.release.complete();
      final firstGeneration = await first;
      final secondGeneration = await second;
      expect(firstGeneration, isNot(TokenStorage.generation));
      expect(secondGeneration, TokenStorage.generation);
      expect(await storage.getToken(), 'account-b');
      expect(await storage.getRefreshToken(), 'refresh-b');
    },
  );

  test(
    'logout deletes both parts of an in-flight session installation',
    () async {
      final disk = DelayedStorage();
      final storage = TokenStorage(storage: disk);
      final installing = storage.saveSession(
        'account-a',
        refreshToken: 'refresh-a',
      );
      await disk.entered.future;
      final clearing = storage.clearToken();
      expect(storage.activeToken, isNull);
      disk.release.complete();
      await installing;
      await clearing;
      expect(disk.values['cozy_health_access_token'], isNull);
      expect(disk.values['cozy_health_refresh_token'], isNull);
    },
  );

  test('logout cannot be undone by a delayed secure token write', () async {
    final disk = DelayedStorage();
    final storage = TokenStorage(storage: disk);
    final saving = storage.saveToken('account-a');
    await disk.entered.future;
    final clearing = storage.clearToken();
    expect(await storage.getToken(), isNull);
    disk.release.complete();
    await Future.wait([saving, clearing]);
    expect(disk.values['cozy_health_access_token'], isNull);
  });

  test('newer account token wins even when the old write is delayed', () async {
    final disk = DelayedStorage();
    final storage = TokenStorage(storage: disk);
    final first = storage.saveToken('account-a');
    await disk.entered.future;
    final second = storage.saveToken('account-b');
    disk.release.complete();
    await Future.wait([first, second]);
    expect(await storage.getToken(), 'account-b');
  });

  test(
    'new access session cannot inherit the old refresh credential',
    () async {
      final disk = DelayedStorage()..delayNext = false;
      final storage = TokenStorage(storage: disk);
      await storage.saveToken('account-a');
      await storage.saveRefreshToken(
        'refresh-a',
        expectedGeneration: TokenStorage.generation,
      );
      await storage.saveToken('account-b');
      expect(await storage.getRefreshToken(), isNull);
    },
  );
}
