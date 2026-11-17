import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/core/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clearToken();
  });
  test(
    'unchecked session removes old saved token and remains usable in memory',
    () async {
      final storage = TokenStorage();
      await storage.saveToken('old', stayLoggedIn: true);
      await storage.saveToken('current', stayLoggedIn: false);
      expect(await storage.getToken(), 'current');
      expect(
        await const FlutterSecureStorage().read(
          key: 'cozy_health_access_token',
        ),
        isNull,
      );
      expect(storage.isSessionOnly, isTrue);
      await storage.clearToken();
      expect(await storage.getToken(), isNull);
    },
  );
  test('checked session persists in secure storage', () async {
    final storage = TokenStorage();
    await storage.saveToken('saved', stayLoggedIn: true);
    expect(
      await const FlutterSecureStorage().read(key: 'cozy_health_access_token'),
      'saved',
    );
    expect(storage.isSessionOnly, isFalse);
  });
  test('journal PIN accepts only four to six ASCII digits', () {
    for (final pin in ['1234', '01234', '123456']) {
      expect(SecurityService.validPin(pin), isTrue);
    }
    for (final pin in ['', '123', '1234567', '123a', '12 34', '1234\n']) {
      expect(SecurityService.validPin(pin), isFalse);
    }
  });
}
