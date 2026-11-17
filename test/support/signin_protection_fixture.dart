import 'dart:async';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:cozy_health/features/auth/data/auth_service.dart';
import 'package:cozy_health/features/auth/data/signin_security.dart';

PendingSignIn attempt(DateTime now, {String method = 'email'}) => PendingSignIn(
  generation: TokenStorage.generation,
  stayLoggedIn: true,
  newAccount: false,
  expectedAccountId: '42',
  expectedEmail: 'owned@example.test',
  challenge: SignInChallenge(
    token: 'a' * 64,
    method: method,
    expiresAt: now.add(const Duration(minutes: 10)),
    questions: method == 'questions'
        ? const [
            SignInQuestion('place', 'Secret place?'),
            SignInQuestion('word', 'Secret word?'),
          ]
        : const [],
    emailDelivery: method == 'email' ? 'queued' : null,
    supportEmail: 'team@cozyhealth.org',
  ),
);
VerifiedSignIn verified(PendingSignIn pending, bool enroll) => VerifiedSignIn(
  attempt: pending,
  data: {
    'challenge_required': false,
    'token': 'owned-provisional',
    'refresh_token': 'd' * 64,
    'device_proof': 'b' * 64,
    'security_settings_token': 'c' * 64,
    'security_enrollment_required': enroll,
    'user': {'id': 42, 'email': 'owned@example.test'},
  },
);

class ProtectionAuth extends AuthService {
  bool enabled = true, enrolled = false, loseSaveResponse = false;
  String method = 'email';
  int finishes = 0,
      discards = 0,
      saves = 0,
      reauthentications = 0,
      verifications = 0;
  Completer<VerifiedSignIn>? delayedVerification;
  ApiException? verificationError;
  final now = DateTime.now().toUtc();
  SignInPreferences get prefs => SignInPreferences(
    enabled: enabled,
    enrolled: enrolled,
    method: method,
    questions: const [
      SignInQuestion('place', 'Secret place?'),
      SignInQuestion('word', 'Secret word?'),
      SignInQuestion('book', 'Secret book?'),
    ],
  );
  @override
  Future<SignInPreferences> signInPreferences({
    VerifiedSignIn? provisional,
  }) async => prefs;
  @override
  Future<VerifiedSignIn> verifySignIn(
    PendingSignIn pending, {
    String? code,
    Map<String, String>? answers,
  }) async {
    verifications++;
    final failure = verificationError;
    if (failure != null) throw failure;
    return delayedVerification != null
        ? delayedVerification!.future
        : verified(pending, !enrolled);
  }

  @override
  Future<PendingSignIn> resendSignIn(PendingSignIn pending) async =>
      pending.withChallenge(
        SignInChallenge(
          token: pending.challenge.token,
          method: 'email',
          expiresAt: pending.challenge.expiresAt,
          questions: const [],
          emailDelivery: 'queued',
          supportEmail: 'team@cozyhealth.org',
        ),
      );
  @override
  Future<Map<String, dynamic>> finishVerifiedSignIn(
    VerifiedSignIn value,
  ) async {
    finishes++;
    await TokenStorage().saveSession(
      value.data['token'] as String,
      refreshToken: value.data['refresh_token'] as String,
    );
    return value.data;
  }

  @override
  Future<void> discardVerifiedSignIn(VerifiedSignIn value) async {
    discards++;
  }

  @override
  Future<SignInPreferences> saveSignInPreferences({
    required String method,
    required String settingsToken,
    List<Map<String, String>>? questions,
    VerifiedSignIn? provisional,
    int? expectedGeneration,
  }) async {
    saves++;
    this.method = method;
    enrolled = true;
    if (loseSaveResponse) throw ApiTimeoutException();
    return prefs;
  }

  @override
  Future<SignInChallenge> verifySecuritySettings(
    String password, {
    int? expectedGeneration,
    VerifiedSignIn? provisional,
  }) async {
    reauthentications++;
    return attempt(now).challenge;
  }

  @override
  Future<String> confirmSecuritySettings(
    SignInChallenge challenge,
    String code, {
    int? expectedGeneration,
  }) async => 'c' * 64;
}
