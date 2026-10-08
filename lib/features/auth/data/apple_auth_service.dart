import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/config/apple_config.dart';

enum AppleSignInResult { success, cancelled, error, notAvailable }

class AppleSignInOutcome {
  final AppleSignInResult result;
  final String? identityToken;
  final String? authorizationCode;
  final String? fullName;
  final String? email;
  final String? errorMessage;
  const AppleSignInOutcome(
    this.result, {
    this.identityToken,
    this.authorizationCode,
    this.fullName,
    this.email,
    this.errorMessage,
  });
}

/// Injectable bridge to the plugin's static SDK API.
class AppleSignInClient {
  Future<bool> isAvailable() => SignInWithApple.isAvailable();
  Future<AuthorizationCredentialAppleID> getCredential() =>
      SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
}

class AppleAuthService {
  final AppleSignInClient _client;
  final bool enabled;
  AppleAuthService({
    AppleSignInClient? client,
    this.enabled = AppleConfig.enabled,
  }) : _client = client ?? AppleSignInClient();

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> isAvailable() async {
    if (!isIOS) return false;
    try {
      return await _client.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<AppleSignInOutcome> signIn() async {
    if (!await isAvailable()) {
      return const AppleSignInOutcome(AppleSignInResult.notAvailable);
    }
    if (!enabled) {
      return const AppleSignInOutcome(
        AppleSignInResult.error,
        errorMessage: 'Apple Sign-In is not configured.',
      );
    }
    try {
      final credential = await _client.getCredential();
      final token = credential.identityToken;
      if (token == null ||
          token.isEmpty ||
          credential.authorizationCode.isEmpty) {
        return const AppleSignInOutcome(
          AppleSignInResult.error,
          errorMessage:
              'Apple did not return complete credentials. Please try again.',
        );
      }
      final name = [credential.givenName, credential.familyName]
          .whereType<String>()
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .join(' ');
      return AppleSignInOutcome(
        AppleSignInResult.success,
        identityToken: token,
        authorizationCode: credential.authorizationCode,
        fullName: name.isEmpty ? null : name,
        email: credential.email,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        return const AppleSignInOutcome(AppleSignInResult.cancelled);
      }
      return const AppleSignInOutcome(
        AppleSignInResult.error,
        errorMessage: 'Apple Sign-In failed. Please try again.',
      );
    } catch (_) {
      return const AppleSignInOutcome(
        AppleSignInResult.error,
        errorMessage:
            'Apple Sign-In failed. Check your connection and try again.',
      );
    }
  }
}
