import 'package:cozy_health/features/auth/data/signin_security.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> challenge() => {
    'challenge_required': true,
    'challenge_token': 'a' * 64,
    'method': 'questions',
    'expires_at': '2026-10-28T12:10:00Z',
    'questions': [
      {'id': 'memorable_place', 'prompt': 'Your memorable place?'},
      {'id': 'memorable_word', 'prompt': 'Your memorable word?'},
    ],
  };

  test('question challenges require two distinct server questions', () {
    final parsed = SignInChallenge.fromJson(challenge());
    expect(parsed.questions.length, 2);
    expect(() => parsed.questions.clear(), throwsUnsupportedError);
    final duplicate = challenge();
    duplicate['questions'] = [
      {'id': 'same', 'prompt': 'First?'},
      {'id': 'same', 'prompt': 'Second?'},
    ];
    expect(() => SignInChallenge.fromJson(duplicate), throwsFormatException);
  });

  test('malformed tokens and unrecognized delivery states fail closed', () {
    for (final replacement in [
      {'challenge_token': 'public-device-id'},
      {'email_delivery': 'delivered'},
      {'challenge_required': false},
      {'method': 'authenticator'},
    ]) {
      expect(
        () => SignInChallenge.fromJson({...challenge(), ...replacement}),
        throwsFormatException,
      );
    }
  });

  test(
    'email fallback preserves the original attempt owner and generation',
    () {
      final original = PendingSignIn(
        challenge: SignInChallenge.fromJson(challenge()),
        generation: 12,
        stayLoggedIn: false,
        newAccount: false,
        expectedAccountId: '42',
      );
      final next = original.withChallenge(
        SignInChallenge.fromJson({
          ...challenge(),
          'method': 'email',
          'questions': [],
          'email_delivery': 'queued',
        }),
      );
      expect(next.expectedAccountId, '42');
      expect(next.generation, 12);
      expect(next.stayLoggedIn, isFalse);
      expect(next.challenge.emailDelivery, 'queued');
    },
  );

  test('verified identity cannot change an account-bound attempt', () {
    final attempt = PendingSignIn(
      challenge: SignInChallenge.fromJson(challenge()),
      generation: 1,
      stayLoggedIn: true,
      newAccount: false,
      expectedAccountId: '42',
    );
    expect(
      () => VerifiedSignIn(
        data: {
          'token': 'session',
          'user': {'id': 99, 'email': 'test@example.com'},
        },
        attempt: attempt,
      ),
      throwsFormatException,
    );
  });

  test('preferences reject unknown authentication methods', () {
    expect(
      () => SignInPreferences.fromJson({
        'enabled': true,
        'enrolled': true,
        'method': 'totp',
        'questions': <String, String>{},
      }),
      throwsFormatException,
    );
  });
}
