import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../../data/auth_service.dart';
import '../../data/google_auth_service.dart';

class GoogleAuthButton extends StatefulWidget {
  final bool enabled;
  final bool stayLoggedIn;
  final ValueChanged<bool>? onLoadingChanged;
  final VoidCallback? onSuccess;
  final GoogleAuthService? googleAuthService;
  final AuthService? authService;
  const GoogleAuthButton({
    super.key,
    this.enabled = true,
    this.stayLoggedIn = true,
    this.onLoadingChanged,
    this.onSuccess,
    this.googleAuthService,
    this.authService,
  });
  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  bool _loading = false;
  late final _google = widget.googleAuthService ?? GoogleAuthService();
  late final _auth = widget.authService ?? AuthService();

  Future<void> _signIn() async {
    if (_loading || !widget.enabled) return;
    setState(() => _loading = true);
    widget.onLoadingChanged?.call(true);
    try {
      final outcome = await _google.signIn();
      if (!mounted || outcome.result == GoogleSignInResult.cancelled) return;
      if (outcome.result == GoogleSignInResult.error) {
        _showError(outcome.errorMessage ?? 'Google Sign-In failed.');
        return;
      }
      final token = outcome.idToken;
      if (token == null || token.isEmpty) {
        _showError('Google did not return an ID token. Please try again.');
        return;
      }
      await _auth.loginWithGoogle(token, stayLoggedIn: widget.stayLoggedIn);
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        final completed = await PersonalizationService()
            .hasCompletedPersonalization();
        if (mounted) {
          context.go(completed ? AppRouter.home : AppRouter.personalization);
        }
      }
    } on ApiException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showError('Unable to sign in. Check your connection and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        widget.onLoadingChanged?.call(false);
      }
    }
  }

  void _showError(String message) {
    AppSnackbar.show(context, AppSnackbar.fromLegacy(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => GoogleSignInButton(
    isLoading: _loading,
    onPressed: widget.enabled && !_loading ? _signIn : null,
  );
}
