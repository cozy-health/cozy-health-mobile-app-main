class SignInQuestion {
  const SignInQuestion(this.id, this.prompt);
  final String id, prompt;
}

class SignInChallenge {
  SignInChallenge({
    required this.token,
    required this.method,
    required this.expiresAt,
    required List<SignInQuestion> questions,
    required this.emailDelivery,
    required this.supportEmail,
  }) : questions = List.unmodifiable(questions);
  final String token, method, supportEmail;
  final DateTime expiresAt;
  final List<SignInQuestion> questions;
  final String? emailDelivery;
  static final tokenPattern = RegExp(r'^[a-f0-9]{64}$');

  factory SignInChallenge.fromJson(Map<String, dynamic> data) {
    final token = data['challenge_token'], method = data['method'];
    final expires = DateTime.tryParse(data['expires_at']?.toString() ?? '');
    if (data['challenge_required'] != true ||
        token is! String ||
        !tokenPattern.hasMatch(token) ||
        !['email', 'questions'].contains(method) ||
        expires == null) {
      throw const FormatException('Invalid sign-in challenge.');
    }
    final questions = <SignInQuestion>[];
    final raw = data['questions'];
    if (raw is List) {
      for (final value in raw) {
        if (value is! Map ||
            value['id'] is! String ||
            value['prompt'] is! String) {
          throw const FormatException('Invalid sign-in question.');
        }
        final id = value['id'] as String, prompt = value['prompt'] as String;
        if (id.isEmpty ||
            id.length > 100 ||
            prompt.isEmpty ||
            prompt.length > 300) {
          throw const FormatException('Invalid sign-in question.');
        }
        questions.add(SignInQuestion(id, prompt));
      }
    }
    if (questions.length > 2 ||
        (method == 'questions' &&
            (questions.length != 2 ||
                questions.map((q) => q.id).toSet().length != 2))) {
      throw const FormatException('Invalid sign-in questions.');
    }
    final delivery = data['email_delivery'];
    if (delivery != null &&
        !['queued', 'failed', 'unavailable'].contains(delivery)) {
      throw const FormatException('Invalid email status.');
    }
    final support = data['support_email'] is String
        ? data['support_email'] as String
        : 'team@cozyhealth.org';
    return SignInChallenge(
      token: token,
      method: method as String,
      expiresAt: expires.toUtc(),
      questions: questions,
      emailDelivery: delivery as String?,
      supportEmail: support,
    );
  }
}

class PendingSignIn {
  const PendingSignIn({
    required this.challenge,
    required this.generation,
    required this.stayLoggedIn,
    required this.newAccount,
    this.expectedAccountId,
    this.expectedEmail,
    this.identityHint,
  });
  final SignInChallenge challenge;
  final int generation;
  final bool stayLoggedIn, newAccount;
  final String? expectedAccountId, expectedEmail, identityHint;
  PendingSignIn withChallenge(SignInChallenge value) => PendingSignIn(
    challenge: value,
    generation: generation,
    stayLoggedIn: stayLoggedIn,
    newAccount: newAccount,
    expectedAccountId: expectedAccountId,
    expectedEmail: expectedEmail,
    identityHint: identityHint,
  );
}

class SignInChallengeRequired implements Exception {
  const SignInChallengeRequired(this.attempt);
  final PendingSignIn attempt;
  @override
  String toString() => 'Additional sign-in verification is required.';
}

class SignInAttemptChanged implements Exception {
  const SignInAttemptChanged();
  String get message => 'This sign-in attempt ended. Start sign-in again.';
  @override
  String toString() => message;
}

/// A verified session is kept in memory until required preference enrollment ends.
class VerifiedSignIn {
  VerifiedSignIn({required Map<String, dynamic> data, required this.attempt})
    : data = Map.unmodifiable(data) {
    final user = data['user'];
    if (data['challenge_required'] != false ||
        data['security_enrollment_required'] is! bool ||
        data['device_proof'] is! String ||
        !SignInChallenge.tokenPattern.hasMatch(
          data['device_proof'] as String,
        ) ||
        data['refresh_token'] is! String ||
        (data['refresh_token'] as String).isEmpty ||
        (data['security_enrollment_required'] == true &&
            (data['security_settings_token'] is! String ||
                !SignInChallenge.tokenPattern.hasMatch(
                  data['security_settings_token'] as String,
                ))) ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty ||
        user is! Map ||
        user['id'] == null ||
        user['email'] is! String ||
        (attempt.expectedAccountId != null &&
            user['id'].toString() != attempt.expectedAccountId) ||
        (attempt.expectedEmail != null &&
            (user['email'] as String).trim().toLowerCase() !=
                attempt.expectedEmail)) {
      throw const FormatException('Invalid verified sign-in identity.');
    }
  }
  final Map<String, dynamic> data;
  final PendingSignIn attempt;
  bool get requiresEnrollment => data['security_enrollment_required'] == true;
  String? get settingsToken => data['security_settings_token'] is String
      ? data['security_settings_token'] as String
      : null;
}

class SignInPreferences {
  SignInPreferences({
    required this.enabled,
    required this.enrolled,
    required this.method,
    required List<SignInQuestion> questions,
  }) : questions = List.unmodifiable(questions);
  final bool enabled, enrolled;
  final String method;
  final List<SignInQuestion> questions;
  factory SignInPreferences.fromJson(Map<String, dynamic> data) {
    final raw = data['questions'];
    if (data['enabled'] is! bool ||
        data['enrolled'] is! bool ||
        !['email', 'questions'].contains(data['method']) ||
        raw is! Map) {
      throw const FormatException('Invalid sign-in preferences.');
    }
    final questions = <SignInQuestion>[];
    for (final entry in raw.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw const FormatException('Invalid question catalog.');
      }
      final id = entry.key as String, prompt = entry.value as String;
      if (id.isEmpty ||
          id.length > 100 ||
          prompt.isEmpty ||
          prompt.length > 300) {
        throw const FormatException('Invalid question catalog.');
      }
      questions.add(SignInQuestion(id, prompt));
    }
    return SignInPreferences(
      enabled: data['enabled'] as bool,
      enrolled: data['enrolled'] as bool,
      method: data['method'] as String,
      questions: questions,
    );
  }
}
