import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/security_gate.dart';
import 'package:cozy_health/core/services/security_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';

void background(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void resume(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clearToken();
  });

  test('PIN and app lock are scoped to the current account', () async {
    var user = 'first';
    final security = SecurityService(userScope: () => user);
    await security.setPin('01234');
    await security.setAppLock(true);
    security.unlockJournal();
    expect(await security.verifyPin('01234'), isTrue);
    user = 'second';
    expect(await security.hasPin(), isFalse);
    expect(await security.appLockEnabled(), isFalse);
    expect(security.journalUnlocked, isFalse);
    user = 'first';
    expect(await security.hasPin(), isTrue);
    expect(await security.appLockEnabled(), isTrue);
    await security.removePin();
    expect(await security.hasPin(), isFalse);
    security.dispose();
  });

  testWidgets('setting a PIN protects an already open journal', (tester) async {
    final security = SecurityService(userScope: () => 'test');
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityGate(
          journal: true,
          security: security,
          child: const Scaffold(body: Text('Private journal content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private journal content'), findsOneWidget);
    await security.setPin('1234');
    await tester.pumpAndSettle();
    expect(find.text('Private journal content'), findsNothing);
    expect(find.text('Enter your journal PIN'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    security.dispose();
  });

  testWidgets('journal detail relocks on reopen and rejects an incorrect PIN', (
    tester,
  ) async {
    final security = SecurityService(userScope: () => 'test');
    await security.setPin('1234');
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityGate(
          journal: true,
          journalRoot: true,
          security: security,
          child: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SecurityGate(
                      journal: true,
                      security: security,
                      child: const Scaffold(
                        body: Text('Private journal detail'),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open detail'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open detail'), findsNothing);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Open journal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open detail'));
    await tester.pumpAndSettle();
    expect(find.text('Private journal detail'), findsOneWidget);
    background(tester);
    await tester.pump();
    expect(find.text('Private journal detail'), findsNothing);
    resume(tester);
    await tester.pumpAndSettle();
    expect(find.text('Enter your journal PIN'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Open journal'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(find.text('Private journal detail'), findsNothing);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Open journal'));
    await tester.pumpAndSettle();
    expect(find.text('Private journal detail'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(security.journalUnlocked, isFalse);
    security.dispose();
  });

  testWidgets('unchecked session expires only after a background reopen', (
    tester,
  ) async {
    var expired = 0;
    final security = SecurityService(userScope: () => 'test');
    await TokenStorage().saveToken('session', stayLoggedIn: false);
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityGate(
          security: security,
          onSessionExpired: () => expired++,
          child: const Scaffold(body: Text('Session content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.text('Session content'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(expired, 0);
    expect(await TokenStorage().getToken(), 'session');
    background(tester);
    await tester.pump();
    resume(tester);
    await tester.pumpAndSettle();
    expect(expired, 1);
    expect(await TokenStorage().getToken(), isNull);
    await tester.pumpWidget(const SizedBox());
    security.dispose();
  });

  testWidgets('failed biometrics stays locked and verifies again on reopen', (
    tester,
  ) async {
    var success = false;
    var calls = 0;
    final security = SecurityService(
      userScope: () => 'test',
      biometricAuthentication: () async {
        calls++;
        return success;
      },
    );
    await security.setAppLock(true);
    await TokenStorage().saveToken('saved', stayLoggedIn: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SecurityGate(
          security: security,
          child: const Scaffold(body: Text('Private app content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Private app content'), findsNothing);
    expect(find.text('Unable to unlock. Try again.'), findsOneWidget);
    success = true;
    await tester.tap(find.text('Unlock with Face ID / biometrics'));
    await tester.pumpAndSettle();
    expect(find.text('Private app content'), findsOneWidget);
    success = false;
    background(tester);
    await tester.pump();
    resume(tester);
    await tester.pumpAndSettle();
    expect(calls, 3);
    expect(find.text('Private app content'), findsNothing);
    expect(await TokenStorage().getToken(), 'saved');
    await tester.pumpWidget(const SizedBox());
    security.dispose();
  });

  testWidgets(
    'authentication received in the background cannot expose the app',
    (tester) async {
      final result = Completer<bool>();
      final security = SecurityService(
        userScope: () => 'test',
        biometricAuthentication: () => result.future,
      );
      await security.setAppLock(true);
      await TokenStorage().saveToken('saved', stayLoggedIn: true);
      await tester.pumpWidget(
        MaterialApp(
          home: SecurityGate(
            security: security,
            child: const Scaffold(body: Text('Private app content')),
          ),
        ),
      );
      await tester.pump();
      background(tester);
      await tester.pump();
      result.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Private app content'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      resume(tester);
      security.dispose();
    },
  );
}
