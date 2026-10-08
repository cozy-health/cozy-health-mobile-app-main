import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/google_config.dart';

enum GoogleSignInResult { success, cancelled, error }

class GoogleSignInOutcome {
  final GoogleSignInResult result;
  final String? idToken;
  final String? errorMessage;
  const GoogleSignInOutcome(this.result, {this.idToken, this.errorMessage});
}

class GoogleAuthService {
  final GoogleSignIn _google;
  static final _initializations = Expando<Future<void>>();
  final String iosClientId;
  final String serverClientId;
  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    this.iosClientId = GoogleConfig.iosClientId,
    this.serverClientId = GoogleConfig.serverClientId,
  }) : _google = googleSignIn ?? GoogleSignIn.instance;

  Future<GoogleSignInOutcome> signIn() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return const GoogleSignInOutcome(
        GoogleSignInResult.error,
        errorMessage: 'Google Sign-In is available on Android and iOS.',
      );
    }
    if (serverClientId.isEmpty ||
        (defaultTargetPlatform == TargetPlatform.iOS && iosClientId.isEmpty)) {
      return const GoogleSignInOutcome(
        GoogleSignInResult.error,
        errorMessage: 'Google Sign-In is not configured.',
      );
    }
    try {
      await (_initializations[_google] ??= _google
          .initialize(
            clientId: defaultTargetPlatform == TargetPlatform.iOS
                ? iosClientId
                : null,
            serverClientId: serverClientId,
          )
          .catchError((Object error) {
            _initializations[_google] = null;
            throw error;
          }));
      final account = await _google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        return const GoogleSignInOutcome(
          GoogleSignInResult.error,
          errorMessage: 'Google did not return an ID token. Please try again.',
        );
      }
      return GoogleSignInOutcome(GoogleSignInResult.success, idToken: token);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return const GoogleSignInOutcome(GoogleSignInResult.cancelled);
      }
      return const GoogleSignInOutcome(
        GoogleSignInResult.error,
        errorMessage: 'Google Sign-In failed. Please try again.',
      );
    } catch (_) {
      return const GoogleSignInOutcome(
        GoogleSignInResult.error,
        errorMessage:
            'Google Sign-In failed. Check your connection and try again.',
      );
    }
  }
}
