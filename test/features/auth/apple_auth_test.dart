import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/data/apple_auth_service.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
import 'package:cozy_health/features/auth/presentation/widgets/apple_auth_button.dart';
import '../../support/repository_fixture.dart';

class FakeAppleClient extends AppleSignInClient {
  bool available = true;
  int availabilityCalls = 0;
  int credentialCalls = 0;
  Object? failure;
  AuthorizationCredentialAppleID credential =
      const AuthorizationCredentialAppleID(
        authorizationCode: 'fake-apple-code',
        identityToken: 'fake-apple-token',
        givenName: ' Ada ',
        familyName: ' Lovelace ',
        email: 'relay@privaterelay.appleid.com',

        userIdentifier: null,
        state: null,
      );
  @override
  Future<bool> isAvailable() async {
    availabilityCalls++;
    return available;
  }

  @override
  Future<AuthorizationCredentialAppleID> getCredential() async {
    credentialCalls++;
    if (failure != null) throw failure!;
    return credential;
  }
}

class FakeAppleService extends AppleAuthService {
  FakeAppleService(this.outcome);
  final Future<AppleSignInOutcome> outcome;
  bool available = true;
  int calls = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<AppleSignInOutcome> signIn() {
    calls++;
    return outcome;
  }
}

class FakeAppleAuth extends AuthService {
  Map<String, dynamic>? received;
  Object? failure;
  @override
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    String? authorizationCode,
    String? fullName,
    String? email,
    bool stayLoggedIn = true,
  }) async {
    received = {
      'identity_token': identityToken,
      'authorization_code': authorizationCode,
      'full_name': fullName,
      'email': email,
      'persistent': stayLoggedIn,
    };
    if (failure != null) throw failure!;
    return {};
  }
}

class FakeAppleApi extends Fake implements ApiClient {
  dynamic response;
  Invocation? request;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #post) {
      request = invocation;
      return Future<dynamic>.value(
        Response<dynamic>(
          data: response,
          requestOptions: RequestOptions(path: '/auth/apple'),
          statusCode: 200,
        ),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class AppleHttpAdapter extends Fake implements HttpClientAdapter {
  AppleHttpAdapter(this.status);
  final int status;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #fetch) {
      return Future<ResponseBody>.value(
        ResponseBody.fromString(
          jsonEncode({'message': 'Apple error $status'}),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
    }
    if (invocation.memberName == #close) return null;
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Apple SDK service', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);
    test(
      'returns token, authorization code and trimmed first-auth fields',
      () async {
        final result = await AppleAuthService(
          client: FakeAppleClient(),
          enabled: true,
        ).signIn();
        expect(result.result, AppleSignInResult.success);
        expect(result.identityToken, 'fake-apple-token');
        expect(result.authorizationCode, 'fake-apple-code');
        expect(result.fullName, 'Ada Lovelace');
        expect(result.email, 'relay@privaterelay.appleid.com');
      },
    );
    test(
      'subsequent authorization omits name/email without inventing defaults',
      () async {
        final client = FakeAppleClient()
          ..credential = const AuthorizationCredentialAppleID(
            authorizationCode: 'next-code',
            identityToken: 'next-token',

            userIdentifier: null,
            givenName: null,
            familyName: null,
            email: null,
            state: null,
          );
        final result = await AppleAuthService(
          client: client,
          enabled: true,
        ).signIn();
        expect(result.result, AppleSignInResult.success);
        expect(result.fullName, isNull);
        expect(result.email, isNull);
        expect(result.authorizationCode, 'next-code');
      },
    );
    test('cancellation maps to silent outcome', () async {
      final client = FakeAppleClient()
        ..failure = const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.canceled,
          message: 'cancelled',
        );
      expect(
        (await AppleAuthService(client: client, enabled: true).signIn()).result,
        AppleSignInResult.cancelled,
      );
    });
    test('Android never invokes Apple SDK', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final client = FakeAppleClient();
      expect(
        (await AppleAuthService(client: client, enabled: true).signIn()).result,
        AppleSignInResult.notAvailable,
      );
      expect(client.availabilityCalls, 0);
      expect(client.credentialCalls, 0);
    });
    test('unavailable iOS never requests credentials', () async {
      final client = FakeAppleClient()..available = false;
      expect(
        (await AppleAuthService(client: client, enabled: true).signIn()).result,
        AppleSignInResult.notAvailable,
      );
      expect(client.credentialCalls, 0);
    });
    test(
      'unconfigured iOS shows graceful error without authorization',
      () async {
        final client = FakeAppleClient();
        final result = await AppleAuthService(
          client: client,
          enabled: false,
        ).signIn();
        expect(result.errorMessage, 'Apple Sign-In is not configured.');
        expect(client.credentialCalls, 0);
      },
    );
    test('missing authorization code is rejected', () async {
      final client = FakeAppleClient()
        ..credential = const AuthorizationCredentialAppleID(
          authorizationCode: '',
          identityToken: 'token',

          userIdentifier: null,
          givenName: null,
          familyName: null,
          email: null,
          state: null,
        );
      expect(
        (await AppleAuthService(client: client, enabled: true).signIn()).result,
        AppleSignInResult.error,
      );
    });
    test('missing identity token is rejected', () async {
      final client = FakeAppleClient()
        ..credential = const AuthorizationCredentialAppleID(
          authorizationCode: 'code',

          userIdentifier: null,
          givenName: null,
          familyName: null,
          email: null,
          identityToken: null,
          state: null,
        );
      expect(
        (await AppleAuthService(client: client, enabled: true).signIn()).result,
        AppleSignInResult.error,
      );
    });
    test('SDK error messages never expose credentials', () async {
      final client = FakeAppleClient()..failure = StateError('private-code');
      final result = await AppleAuthService(
        client: client,
        enabled: true,
      ).signIn();
      expect(result.result, AppleSignInResult.error);
      expect(result.errorMessage, isNot(contains('private-code')));
    });
    test('real SDK bridge requests email and fullName scopes', () async {
      const channel = MethodChannel(
        'com.aboutyou.dart_packages.sign_in_with_apple',
      );
      MethodCall? request;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isAvailable') return true;
            request = call;
            return {
              'type': 'appleid',
              'authorizationCode': 'sdk-code',
              'identityToken': 'sdk-token',
              'givenName': 'Ada',
              'familyName': 'Lovelace',
              'email': 'first@example.test',
            };
          });
      try {
        final result = await AppleAuthService(enabled: true).signIn();
        expect(result.result, AppleSignInResult.success);
        expect(result.authorizationCode, 'sdk-code');
        expect(request!.method, 'performAuthorizationRequest');
        expect((request!.arguments as List).single['scopes'], [
          'email',
          'fullName',
        ]);
      } finally {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      }
    });
  });

  Future<void> mount(
    WidgetTester tester,
    FakeAppleService service,
    FakeAppleAuth auth, {
    VoidCallback? onSuccess,
    bool enabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppleAuthButton(
            appleAuthService: service,
            authService: auth,
            onSuccess: onSuccess,
            enabled: enabled,
            stayLoggedIn: false,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'success forwards tokens, code, name/email; loading disables duplicate taps',
    (tester) async {
      final pending = Completer<AppleSignInOutcome>();
      final service = FakeAppleService(pending.future);
      final auth = FakeAppleAuth();
      var succeeded = 0;
      await mount(tester, service, auth, onSuccess: () => succeeded++);
      expect(
        tester
            .widget<SignInWithAppleButton>(find.byType(SignInWithAppleButton))
            .height,
        56,
      );
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SignInWithAppleButton), findsNothing);
      pending.complete(
        const AppleSignInOutcome(
          AppleSignInResult.success,
          identityToken: 'token',
          authorizationCode: 'code',
          fullName: 'Ada',
          email: 'first@example.test',
        ),
      );
      await tester.pumpAndSettle();
      expect(auth.received, {
        'identity_token': 'token',
        'authorization_code': 'code',
        'full_name': 'Ada',
        'email': 'first@example.test',
        'persistent': false,
      });
      expect(succeeded, 1);
      expect(service.calls, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'cancelled flow makes no API call and no SnackBar',
    (tester) async {
      final auth = FakeAppleAuth();
      await mount(
        tester,
        FakeAppleService(
          Future.value(const AppleSignInOutcome(AppleSignInResult.cancelled)),
        ),
        auth,
      );
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(auth.received, isNull);
      expect(find.byType(SnackBar), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'button is hidden on Android',
    (tester) async {
      await mount(
        tester,
        FakeAppleService(
          Future.value(const AppleSignInOutcome(AppleSignInResult.cancelled)),
        ),
        FakeAppleAuth(),
      );
      expect(find.byType(SignInWithAppleButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
  testWidgets(
    'button is hidden when iOS SDK is unavailable',
    (tester) async {
      final service = FakeAppleService(
        Future.value(const AppleSignInOutcome(AppleSignInResult.notAvailable)),
      )..available = false;
      await mount(tester, service, FakeAppleAuth());
      expect(find.byType(SignInWithAppleButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'notAvailable outcome hides button and makes no API call',
    (tester) async {
      final auth = FakeAppleAuth();
      await mount(
        tester,
        FakeAppleService(
          Future.value(
            const AppleSignInOutcome(AppleSignInResult.notAvailable),
          ),
        ),
        auth,
      );
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(auth.received, isNull);
      expect(find.byType(SignInWithAppleButton), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    'SDK errors show SnackBar',
    (tester) async {
      final auth = FakeAppleAuth();
      await mount(
        tester,
        FakeAppleService(
          Future.value(
            const AppleSignInOutcome(
              AppleSignInResult.error,
              errorMessage: 'Apple Sign-In is not configured.',
            ),
          ),
        ),
        auth,
      );
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(find.text('Apple Sign-In is not configured.'), findsOneWidget);
      expect(auth.received, isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  testWidgets(
    '409 shows linking-specific error and no success',
    (tester) async {
      final auth = FakeAppleAuth()
        ..failure = ApiValidationException({}, 'Collision', statusCode: 409);
      await mount(
        tester,
        FakeAppleService(
          Future.value(
            const AppleSignInOutcome(
              AppleSignInResult.success,
              identityToken: 'token',
              authorizationCode: 'code',
            ),
          ),
        ),
        auth,
      );
      await tester.tap(find.text('Sign in with Apple'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This Apple ID could not be linked. Please sign in with your existing account.',
        ),
        findsOneWidget,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  group('Apple errors and log redaction', () {
    for (final status in [401, 403, 409, 422, 503]) {
      test('$status preserves backend message and existing session', () async {
        FlutterSecureStorage.setMockInitialValues({});
        final storage = TokenStorage();
        await storage.saveToken('existing-session');
        final dio = Dio()..httpClientAdapter = AppleHttpAdapter(status);
        dio.interceptors.addAll([AuthInterceptor(), ErrorInterceptor()]);
        try {
          await dio.post(
            '/auth/apple',
            data: {'identity_token': 'token', 'authorization_code': 'code'},
            options: Options(extra: {'skipAuth': true}),
          );
          fail('Expected rejection');
        } on DioException catch (error) {
          final apiError = error.error as ApiException;
          expect(apiError.statusCode, status);
          expect(apiError.message, 'Apple error $status');
        }
        expect(await storage.getToken(), 'existing-session');
        await storage.clearToken();
        dio.close();
      });
    }
    test(
      'identity token, authorization code, name/email are redacted',
      () async {
        final messages = <String>[];
        final previous = debugPrint;
        debugPrint = (String? message, {int? wrapWidth}) {
          if (message != null) messages.add(message);
        };
        final dio = Dio()..httpClientAdapter = AppleHttpAdapter(200);
        dio.interceptors.add(LoggingInterceptor());
        try {
          await dio.post(
            '/auth/apple',
            data: {
              'identity_token': 'private-token',
              'authorization_code': 'private-code',
              'full_name': 'private-name',
              'email': 'private-email',
            },
          );
          expect(messages.join(), contains('<redacted>'));
          for (final value in [
            'private-token',
            'private-code',
            'private-name',
            'private-email',
          ]) {
            expect(messages.join(), isNot(contains(value)));
          }
        } finally {
          debugPrint = previous;
          dio.close();
        }
      },
    );
  });

  group('Apple backend session', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);
    final fixture = RepositoryFixture<UserProfile>(
      LocalDbService.userProfileBoxName,
      UserProfileAdapter(),
    );
    final user = {
      'id': 43,
      'name': 'Apple User',
      'email': 'relay@privaterelay.appleid.com',
    };
    setUpAll(fixture.open);
    tearDownAll(fixture.close);
    setUp(() async {
      await fixture.reset();
      fixture.body = {'data': user};
      SharedPreferences.setMockInitialValues({'is_guest_session': true});
    });
    test(
      'real AuthService forwards all values and establishes session/cache',
      () async {
        final api = FakeAppleApi()
          ..response = {
            'success': true,
            'data': {'user': user, 'token': 'sanctum-token'},
          };
        final storage = TokenStorage();
        await AuthService(apiClient: api, tokenStorage: storage).loginWithApple(
          identityToken: 'identity',
          authorizationCode: 'code',
          fullName: 'Apple User',
          email: 'relay@privaterelay.appleid.com',
          stayLoggedIn: false,
        );
        expect(api.request!.positionalArguments.single, '/auth/apple');
        expect(api.request!.namedArguments[#withAuth], false);
        expect(api.request!.namedArguments[#body], {
          'identity_token': 'identity',
          'authorization_code': 'code',
          'full_name': 'Apple User',
          'email': 'relay@privaterelay.appleid.com',
          'device_name': 'iOS',
        });
        expect(await storage.getToken(), 'sanctum-token');
        expect(storage.isSessionOnly, true);
        expect(fixture.box.values.first.id, '43');
        expect(
          (await SharedPreferences.getInstance()).getBool('is_guest_session'),
          isNull,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await storage.clearToken();
      },
    );
    test(
      'later sign-in omits absent first-auth fields and persists token',
      () async {
        final api = FakeAppleApi()
          ..response = {
            'success': true,
            'data': {'user': user, 'token': 'saved-token'},
          };
        final storage = TokenStorage();
        await AuthService(apiClient: api, tokenStorage: storage).loginWithApple(
          identityToken: 'identity',
          authorizationCode: 'next-code',
        );
        final body = api.request!.namedArguments[#body] as Map;
        expect(body.containsKey('full_name'), false);
        expect(body.containsKey('email'), false);
        expect(body['authorization_code'], 'next-code');
        expect(storage.isSessionOnly, false);
        expect(await storage.getToken(), 'saved-token');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await storage.clearToken();
      },
    );
    test('missing backend token does not establish session', () async {
      final api = FakeAppleApi()
        ..response = {
          'success': true,
          'data': {'user': user},
        };
      final storage = TokenStorage();
      await storage.clearToken();
      await expectLater(
        AuthService(
          apiClient: api,
          tokenStorage: storage,
        ).loginWithApple(identityToken: 'identity', authorizationCode: 'code'),
        throwsFormatException,
      );
      expect(await storage.getToken(), isNull);
      expect(fixture.box.isEmpty, true);
    });
  });
}
