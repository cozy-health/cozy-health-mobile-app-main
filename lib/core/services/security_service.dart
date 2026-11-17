import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'local_db_service.dart';

class SecurityService extends ChangeNotifier {
  static final instance = SecurityService();
  SecurityService({
    FlutterSecureStorage? storage,
    String Function()? userScope,
    Future<bool> Function()? biometricAuthentication,
  }) : storage = storage ?? const FlutterSecureStorage(),
       _userScope = userScope,
       _biometricAuthentication = biometricAuthentication;

  final FlutterSecureStorage storage;
  final String Function()? _userScope;
  final Future<bool> Function()? _biometricAuthentication;
  String? _unlockedJournalScope;
  bool authenticating = false;
  String get _scope =>
      _userScope?.call() ??
      (LocalDbService.instance.isUserProfileBoxOpen
          ? LocalDbService.instance.getUserProfile()?.id ?? 'guest'
          : 'guest');
  String get _lockKey => 'app_lock_$_scope';
  String get _pinKey => 'journal_pin_$_scope';
  bool get journalUnlocked => _unlockedJournalScope == _scope;

  void unlockJournal() {
    _unlockedJournalScope = _scope;
    notifyListeners();
  }

  void lockJournal() {
    if (_unlockedJournalScope == null) return;
    _unlockedJournalScope = null;
    notifyListeners();
  }

  Future<bool> appLockEnabled() async =>
      await storage.read(key: _lockKey) == 'true';
  Future<void> setAppLock(bool value) =>
      storage.write(key: _lockKey, value: '$value');
  Future<bool> hasPin() async => await storage.read(key: _pinKey) != null;
  static bool validPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);
  Future<void> setPin(String pin) async {
    if (!validPin(pin)) throw ArgumentError('Use 4–6 digits.');
    await storage.write(key: _pinKey, value: pin);
    _unlockedJournalScope = null;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async =>
      validPin(pin) && await storage.read(key: _pinKey) == pin;
  Future<void> removePin() async {
    await storage.delete(key: _pinKey);
    _unlockedJournalScope = null;
    notifyListeners();
  }

  Future<bool> authenticate() async {
    if (authenticating) return false;
    authenticating = true;
    try {
      if (_biometricAuthentication != null) {
        return await _biometricAuthentication();
      }
      return await LocalAuthentication().authenticate(
        localizedReason: 'Unlock Cozy Health',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    } finally {
      authenticating = false;
      notifyListeners();
    }
  }
}
