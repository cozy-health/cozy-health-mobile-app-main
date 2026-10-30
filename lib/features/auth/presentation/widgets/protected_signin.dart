import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_service.dart';
import '../../data/signin_security.dart';
import '../screens/signin_protection_screen.dart';

/// Every sign-in entry point handles pending checks before navigating privately.
Future<Map<String, dynamic>?> runProtectedSignIn(
  BuildContext context,
  AuthService auth,
  Future<Map<String, dynamic>> Function() submit, {
  VoidCallback? clearSecrets,
}) async {
  try {
    return await submit();
  } on SignInChallengeRequired catch (required) {
    clearSecrets?.call();
    if (!context.mounted) return null;
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) =>
            SignInProtectionScreen(attempt: required.attempt, auth: auth),
      ),
    );
    if (result == null) {
      if (required.attempt.newAccount && context.mounted) {
        GoRouter.maybeOf(context)?.go('/login');
      }
      return null;
    }
    final token = result['token'];
    if (token is! String || token != TokenStorage().activeToken) {
      throw const SignInAttemptChanged();
    }
    return result;
  }
}
