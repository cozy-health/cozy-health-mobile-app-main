import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/features/auth/data/signin_security.dart';
import 'dart:async';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/presentation/controllers/signin_protection_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/signin_protection_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clearToken();
  });
  test(
    'bootstrap enrollment keeps credentials inactive until three valid answers are saved',
    () async {
      final auth = ProtectionAuth();
      final model = SignInProtectionController(
        auth: auth,
        attempt: attempt(auth.now),
      );
      await model.verify(code: '123456');
      expect(model.step, ProtectionStep.preferences);
      expect(await TokenStorage().getToken(), isNull);
      await model.save([
        {'id': 'place', 'answer': 'abc'},
      ]);
      expect(auth.saves, 0);
      expect(auth.finishes, 0);
      await model.save([
        for (final id in ['place', 'word', 'book'])
          {'id': id, 'answer': 'a private test answer'},
      ]);
      expect(auth.saves, 1);
      expect(auth.finishes, 1);
      expect(model.step, ProtectionStep.done);
      expect(await TokenStorage().getToken(), 'owned-provisional');
      model.dispose();
    },
  );
  test('late verification cannot replace a newly signed-in account', () async {
    final auth = ProtectionAuth()
      ..delayedVerification = Completer<VerifiedSignIn>();
    final pending = attempt(auth.now);
    final model = SignInProtectionController(auth: auth, attempt: pending);
    final work = model.verify(code: '123456');
    await Future<void>.delayed(Duration.zero);
    await TokenStorage().saveSession(
      'new-account',
      refreshToken: 'new-refresh',
    );
    auth.delayedVerification!.complete(verified(pending, false));
    await work;
    expect(auth.finishes, 0);
    expect(auth.discards, 1);
    expect(await TokenStorage().getToken(), 'new-account');
    expect(model.step, ProtectionStep.ended);
    model.dispose();
  });
  test(
    'lost save response requires explicit reconciliation and continuation',
    () async {
      final auth = ProtectionAuth()..loseSaveResponse = true;
      final model = SignInProtectionController(
        auth: auth,
        attempt: attempt(auth.now),
      );
      await model.verify(code: '123456');
      model.chooseMethod('email');
      await model.save([]);
      expect(model.uncertain, true);
      expect(model.hasTicket, false);
      expect(auth.finishes, 0);
      expect(await TokenStorage().getToken(), isNull);
      await model.reconcile();
      expect(model.step, ProtectionStep.ready);
      expect(auth.finishes, 0);
      await model.continueSaved();
      expect(auth.finishes, 1);
      model.dispose();
    },
  );
  test(
    'question fallback uses email only after cooldown and preserves expiry',
    () async {
      final auth = ProtectionAuth();
      var now = auth.now;
      final model = SignInProtectionController(
        auth: auth,
        attempt: attempt(now, method: 'questions'),
        now: () => now,
      );
      final expiry = model.challenge!.expiresAt;
      await model.resend();
      expect(model.challenge!.method, 'questions');
      now = now.add(const Duration(seconds: 61));
      await model.resend();
      expect(model.challenge!.method, 'email');
      expect(model.challenge!.expiresAt, expiry);
      expect(model.resendSeconds, 60);
      now = now.add(const Duration(minutes: 11));
      await model.verify(code: '123456');
      expect(auth.verifications, 0);
      model.dispose();
    },
  );
  test(
    'settings verification cannot continue after the account changes',
    () async {
      final auth = ProtectionAuth();
      final model = SignInProtectionController(auth: auth, settings: true);
      await model.loadPreferences();
      await model.beginSettings('test-only-password');
      expect(model.step, ProtectionStep.settingsCode);
      await TokenStorage().saveToken('next-account');
      await model.verify(code: '123456');
      expect(auth.saves, 0);
      expect(model.step, ProtectionStep.ended);
      expect(await TokenStorage().getToken(), 'next-account');
      model.dispose();
    },
  );
  test(
    'disabled setup remains honestly held and does not activate a session',
    () async {
      final auth = ProtectionAuth()..enabled = false;
      final model = SignInProtectionController(auth: auth, settings: true);
      await model.loadPreferences();
      expect(model.step, ProtectionStep.held);
      expect(auth.saves, 0);
      expect(auth.finishes, 0);
      model.dispose();
    },
  );
  test(
    'cancelling enrollment revokes only its provisional credential',
    () async {
      final auth = ProtectionAuth();
      final model = SignInProtectionController(
        auth: auth,
        attempt: attempt(auth.now),
      );
      await model.verify(code: '123456');
      await model.cancel();
      await model.cancel();
      expect(auth.discards, 1);
      expect(auth.finishes, 0);
      expect(await TokenStorage().getToken(), isNull);
      model.dispose();
    },
  );

  test(
    'rate limits prevent another verification until Retry-After elapses',
    () async {
      final auth = ProtectionAuth()
        ..verificationError = ApiRateLimitException(
          'Wait before retrying.',
          120,
        );
      var now = auth.now;
      final model = SignInProtectionController(
        auth: auth,
        attempt: attempt(now),
        now: () => now,
      );
      await model.verify(code: '123456');
      expect(model.blockedSeconds, 120);
      expect(model.error, 'Wait before retrying.');
      await model.verify(code: '123456');
      expect(auth.verifications, 1);
      expect(auth.finishes, 0);
      now = now.add(const Duration(seconds: 121));
      auth.verificationError = null;
      await model.verify(code: '123456');
      expect(auth.verifications, 2);
      expect(model.step, ProtectionStep.preferences);
      expect(auth.finishes, 0);
      model.dispose();
    },
  );
  test(
    'settings changes require password and fresh email proof without replacing the session',
    () async {
      await TokenStorage().saveToken('current-owner');
      final auth = ProtectionAuth()..enrolled = true;
      final model = SignInProtectionController(auth: auth, settings: true);
      await model.loadPreferences();
      expect(model.step, ProtectionStep.identity);
      await model.save([]);
      expect(auth.saves, 0);
      await model.beginSettings('test-only-password');
      expect(model.step, ProtectionStep.settingsCode);
      expect(model.hasTicket, false);
      await model.verify(code: '123456');
      expect(model.hasTicket, true);
      model.chooseMethod('questions');
      await model.save([
        for (final id in ['place', 'word', 'book'])
          {'id': id, 'answer': 'a private answer'},
      ]);
      expect(model.step, ProtectionStep.done);
      expect(auth.reauthentications, 1);
      expect(auth.saves, 1);
      expect(auth.finishes, 0);
      expect(await TokenStorage().getToken(), 'current-owner');
      model.dispose();
    },
  );
}
