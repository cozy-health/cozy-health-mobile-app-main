import 'dart:async';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
import 'package:cozy_health/features/auth/data/signin_security.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/signin_protection_fixture.dart';

class ProtectionApi extends Fake implements ApiClient {
  final verification = Completer<dynamic>();
  final calls = <Invocation>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    if (invocation.memberName == #post) {
      final path = invocation.positionalArguments.first;
      if (path == '/auth/challenge/verify') {
        return verification.future.then(
          (data) => Response<dynamic>(
            data: data,
            requestOptions: RequestOptions(path: path.toString()),
            statusCode: 200,
          ),
        );
      }
      if (path == '/auth/logout') {
        return Future<dynamic>.value({'success': true});
      }
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await TokenStorage().clearToken();
  });
  test(
    'late actual verification revokes only its provisional credential and preserves the new account',
    () async {
      final api = ProtectionApi();
      final auth = AuthService(apiClient: api);
      final pending = attempt(DateTime.now().toUtc());
      final work = auth.verifySignIn(pending, code: '123456');
      final rejected = expectLater(work, throwsA(isA<SignInAttemptChanged>()));
      await TokenStorage().saveToken('new-account');
      api.verification.complete({'data': verified(pending, true).data});
      await rejected;
      await Future<void>.delayed(Duration.zero);
      final revocations = api.calls.where(
        (call) => call.positionalArguments.first == '/auth/logout',
      );
      expect(revocations.length, 1);
      final revoke = revocations.single;
      expect(revoke.namedArguments[#withAuth], false);
      expect(
        (revoke.namedArguments[#options] as Options).headers?['Authorization'],
        'Bearer owned-provisional',
      );
      expect(await TokenStorage().getToken(), 'new-account');
    },
  );
  test(
    'a response for a different email cannot become a verified credential',
    () async {
      final api = ProtectionApi();
      final auth = AuthService(apiClient: api);
      final pending = attempt(DateTime.now().toUtc());
      final work = auth.verifySignIn(pending, code: '123456');
      final rejected = expectLater(work, throwsFormatException);
      api.verification.complete({
        'data': {
          ...verified(pending, true).data,
          'user': {'id': 42, 'email': 'other@example.test'},
        },
      });
      await rejected;
      expect(await TokenStorage().getToken(), isNull);
    },
  );
  test(
    'settings operations with an old generation fail before making HTTP requests',
    () async {
      final api = ProtectionApi();
      final auth = AuthService(apiClient: api);
      final generation = TokenStorage.generation;
      await TokenStorage().saveToken('new-account');
      await expectLater(
        auth.verifySecuritySettings('password', expectedGeneration: generation),
        throwsA(isA<SignInAttemptChanged>()),
      );
      await expectLater(
        auth.confirmSecuritySettings(
          attempt(DateTime.now()).challenge,
          '123456',
          expectedGeneration: generation,
        ),
        throwsA(isA<SignInAttemptChanged>()),
      );
      await expectLater(
        auth.saveSignInPreferences(
          method: 'email',
          settingsToken: 'c' * 64,
          expectedGeneration: generation,
        ),
        throwsA(isA<SignInAttemptChanged>()),
      );
      expect(api.calls, isEmpty);
      expect(await TokenStorage().getToken(), 'new-account');
    },
  );
}
