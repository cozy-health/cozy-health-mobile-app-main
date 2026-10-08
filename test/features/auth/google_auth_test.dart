import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
import 'package:cozy_health/features/auth/data/google_auth_service.dart';
import 'package:cozy_health/features/auth/presentation/widgets/google_auth_button.dart';
import '../../support/repository_fixture.dart';

class FakeGoogle extends Fake implements GoogleSignIn {
  int initialized = 0;
  int authenticated = 0;
  String? serverId;
  Object? failure;
  String? token = 'fake-google-id-token';
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #initialize) {
      initialized++;
      serverId = invocation.namedArguments[#serverClientId] as String?;
      return Future<void>.value();
    }
    if (invocation.memberName == #authenticate) {
      authenticated++;
      return failure == null
          ? Future<GoogleSignInAccount>.value(FakeAccount(token))
          : Future<GoogleSignInAccount>.error(failure!);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeAccount extends Fake implements GoogleSignInAccount {
  FakeAccount(this.token);
  final String? token;
  @override
  GoogleSignInAuthentication get authentication =>
      GoogleSignInAuthentication(idToken: token);
}

class FakeGoogleService extends GoogleAuthService {
  FakeGoogleService(this.outcome);
  final Future<GoogleSignInOutcome> outcome;
  int calls = 0;
  @override
  Future<GoogleSignInOutcome> signIn() {
    calls++;
    return outcome;
  }
}

class FakeAuth extends AuthService {
  String? receivedToken;
  bool? persistent;
  Object? failure;
  @override
  Future<Map<String, dynamic>> loginWithGoogle(
    String idToken, {
    bool stayLoggedIn = true,
  }) async {
    receivedToken = idToken;
    persistent = stayLoggedIn;
    if (failure != null) throw failure!;
    return {};
  }
}

class FakeApi extends Fake implements ApiClient {
  dynamic response;
  Object? failure;
  Invocation? request;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #post) {
      request = invocation;
      return failure == null
          ? Future<dynamic>.value(
              Response<dynamic>(
                data: response,
                requestOptions: RequestOptions(path: '/auth/google'),
                statusCode: 200,
              ),
            )
          : Future<dynamic>.error(failure!);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakeHttpAdapter extends Fake implements HttpClientAdapter {
  FakeHttpAdapter(this.status, this.message);
  final int status;
  final String message;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #fetch) {
      return Future<ResponseBody>.value(
        ResponseBody.fromString(
          jsonEncode({'message': message}),
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
  group('Google API errors and logging', () {
    for (final status in [401, 403, 422, 503]) {
      test('$status preserves backend message and existing token', () async {
        FlutterSecureStorage.setMockInitialValues({});
        final storage = TokenStorage();
        await storage.saveToken('existing-session');
        final dio = Dio()
          ..httpClientAdapter = FakeHttpAdapter(
            status,
            'Provider error $status',
          );
        dio.interceptors.addAll([AuthInterceptor(), ErrorInterceptor()]);
        try {
          await dio.post(
            '/auth/google',
            data: {'id_token': 'private-token'},
            options: Options(extra: {'skipAuth': true}),
          );
          fail('Expected rejection');
        } on DioException catch (error) {
          final apiError = error.error as ApiException;
          expect(apiError.statusCode, status);
          expect(apiError.message, 'Provider error $status');
        }
        expect(await storage.getToken(), 'existing-session');
        await storage.clearToken();
        dio.close();
      });
    }
    test('Google ID token is redacted from request logging', () async {
      final messages = <String>[];
      final previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };
      final dio = Dio()..httpClientAdapter = FakeHttpAdapter(200, 'OK');
      dio.interceptors.add(LoggingInterceptor());
      try {
        await dio.post(
          '/auth/google',
          data: {'id_token': 'private-token-never-log'},
        );
        expect(messages.join(), contains('<redacted>'));
        expect(messages.join(), isNot(contains('private-token-never-log')));
      } finally {
        debugPrint = previous;
        dio.close();
      }
    });
  });
  group('Google SDK', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);
    test(
      'returns ID token and initializes once across service instances',
      () async {
        final sdk = FakeGoogle();
        final service = GoogleAuthService(
          googleSignIn: sdk,
          serverClientId: 'test-server-id',
        );
        final result = await service.signIn();
        expect(result.result, GoogleSignInResult.success);
        expect(result.idToken, 'fake-google-id-token');
        await GoogleAuthService(
          googleSignIn: sdk,
          serverClientId: 'test-server-id',
        ).signIn();
        expect(sdk.initialized, 1);
        expect(sdk.serverId, 'test-server-id');
      },
    );
    test('SDK cancellation is a silent outcome', () async {
      final sdk = FakeGoogle()
        ..failure = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
      expect(
        (await GoogleAuthService(
          googleSignIn: sdk,
          serverClientId: 'test',
        ).signIn()).result,
        GoogleSignInResult.cancelled,
      );
    });
    test('missing configuration does not invoke native SDK', () async {
      final sdk = FakeGoogle();
      final result = await GoogleAuthService(
        googleSignIn: sdk,
        serverClientId: '',
      ).signIn();
      expect(result.errorMessage, 'Google Sign-In is not configured.');
      expect(sdk.initialized, 0);
      expect(sdk.authenticated, 0);
    });
    test('missing ID token is an error', () async {
      final sdk = FakeGoogle()..token = null;
      expect(
        (await GoogleAuthService(
          googleSignIn: sdk,
          serverClientId: 'test',
        ).signIn()).result,
        GoogleSignInResult.error,
      );
    });
    test('SDK errors are sanitized', () async {
      final sdk = FakeGoogle()..failure = StateError('private diagnostic');
      final result = await GoogleAuthService(
        googleSignIn: sdk,
        serverClientId: 'test',
      ).signIn();
      expect(result.result, GoogleSignInResult.error);
      expect(result.errorMessage, isNot(contains('private diagnostic')));
    });
  });

  Future<void> mount(
    WidgetTester tester,
    FakeGoogleService google,
    FakeAuth auth, {
    VoidCallback? onSuccess,
    bool enabled = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GoogleAuthButton(
          googleAuthService: google,
          authService: auth,
          onSuccess: onSuccess,
          enabled: enabled,
          stayLoggedIn: false,
        ),
      ),
    ),
  );

  testWidgets(
    'success forwards token and completes once; loading blocks duplicate taps',
    (tester) async {
      final pending = Completer<GoogleSignInOutcome>();
      final google = FakeGoogleService(pending.future);
      final auth = FakeAuth();
      var succeeded = 0;
      await mount(tester, google, auth, onSuccess: () => succeeded++);
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      pending.complete(
        const GoogleSignInOutcome(
          GoogleSignInResult.success,
          idToken: 'fake-token',
        ),
      );
      await tester.pumpAndSettle();
      expect(auth.receivedToken, 'fake-token');
      expect(auth.persistent, false);
      expect(succeeded, 1);
      expect(google.calls, 1);
    },
  );
  testWidgets('cancelled flow makes no backend call and shows no error', (
    tester,
  ) async {
    final auth = FakeAuth();
    await mount(
      tester,
      FakeGoogleService(
        Future.value(const GoogleSignInOutcome(GoogleSignInResult.cancelled)),
      ),
      auth,
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(auth.receivedToken, isNull);
    expect(find.byType(SnackBar), findsNothing);
  });
  testWidgets('SDK error shows SnackBar without backend call', (tester) async {
    final auth = FakeAuth();
    await mount(
      tester,
      FakeGoogleService(
        Future.value(
          const GoogleSignInOutcome(
            GoogleSignInResult.error,
            errorMessage: 'Google Sign-In is not configured.',
          ),
        ),
      ),
      auth,
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('Google Sign-In is not configured.'), findsOneWidget);
    expect(auth.receivedToken, isNull);
  });
  testWidgets('backend disabled-account message is shown', (tester) async {
    final auth = FakeAuth()
      ..failure = ApiValidationException(
        {},
        'This account has been disabled.',
        statusCode: 403,
      );
    await mount(
      tester,
      FakeGoogleService(
        Future.value(
          const GoogleSignInOutcome(
            GoogleSignInResult.success,
            idToken: 'fake',
          ),
        ),
      ),
      auth,
    );
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('This account has been disabled.'), findsOneWidget);
  });
  testWidgets('disabled button does not start SDK', (tester) async {
    final google = FakeGoogleService(
      Future.value(const GoogleSignInOutcome(GoogleSignInResult.cancelled)),
    );
    await mount(tester, google, FakeAuth(), enabled: false);
    await tester.tap(find.text('Continue with Google'));
    expect(google.calls, 0);
  });

  group('backend session', () {
    final fixture = RepositoryFixture<UserProfile>(
      LocalDbService.userProfileBoxName,
      UserProfileAdapter(),
    );
    final user = {'id': 42, 'name': 'Test User', 'email': 'test@example.test'};
    setUpAll(fixture.open);
    tearDownAll(fixture.close);
    setUp(() async {
      await fixture.reset();
      fixture.body = {'data': user};
      SharedPreferences.setMockInitialValues({'is_guest_session': true});
    });
    test(
      'real AuthService posts token, stores session, caches user and exits guest mode',
      () async {
        final api = FakeApi()
          ..response = {
            'success': true,
            'data': {'user': user, 'token': 'sanctum-test-token'},
          };
        final storage = TokenStorage();
        await AuthService(
          apiClient: api,
          tokenStorage: storage,
        ).loginWithGoogle('fake-id-token', stayLoggedIn: false);
        expect(api.request!.positionalArguments.single, '/auth/google');
        expect(api.request!.namedArguments[#withAuth], false);
        expect(
          (api.request!.namedArguments[#body] as Map)['id_token'],
          'fake-id-token',
        );
        expect(await storage.getToken(), 'sanctum-test-token');
        expect(storage.isSessionOnly, true);
        expect(
          fixture.box.get('current')?.id ?? fixture.box.values.first.id,
          '42',
        );
        expect(
          (await SharedPreferences.getInstance()).getBool('is_guest_session'),
          isNull,
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await storage.clearToken();
      },
    );
    test('missing backend token never establishes session', () async {
      final api = FakeApi()
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
        ).loginWithGoogle('fake'),
        throwsFormatException,
      );
      expect(await storage.getToken(), isNull);
      expect(fixture.box.isEmpty, true);
    });
  });
}
