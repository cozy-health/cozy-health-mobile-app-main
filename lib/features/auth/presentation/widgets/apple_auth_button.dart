import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/widgets/apple_sign_in_button.dart';
import '../../data/apple_auth_service.dart';
import '../../data/auth_service.dart';

class AppleAuthButton extends StatefulWidget {
  final bool enabled;
  final bool stayLoggedIn;
  final ValueChanged<bool>? onLoadingChanged;
  final VoidCallback? onSuccess;
  final AppleAuthService? appleAuthService;
  final AuthService? authService;
  const AppleAuthButton({
    super.key,
    this.enabled = true,
    this.stayLoggedIn = true,
    this.onLoadingChanged,
    this.onSuccess,
    this.appleAuthService,
    this.authService,
  });
  @override
  State<AppleAuthButton> createState() => _AppleAuthButtonState();
}

class _AppleAuthButtonState extends State<AppleAuthButton> {
  bool _available = false;
  bool _loading = false;
  late final _apple = widget.appleAuthService ?? AppleAuthService();
  late final _auth = widget.authService ?? AuthService();

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (!AppleAuthService.isIOS) return;
    final available = await _apple.isAvailable();
    if (mounted) setState(() => _available = available);
  }

  Future<void> _signIn() async {
    if (_loading || !widget.enabled) return;
    setState(() => _loading = true);
    widget.onLoadingChanged?.call(true);
    try {
      final outcome = await _apple.signIn();
      if (!mounted || outcome.result == AppleSignInResult.cancelled) return;
      if (outcome.result == AppleSignInResult.notAvailable) {
        setState(() => _available = false);
        return;
      }
      if (outcome.result == AppleSignInResult.error) {
        _showError(outcome.errorMessage ?? 'Apple Sign-In failed.');
        return;
      }
      final token = outcome.identityToken;
      final code = outcome.authorizationCode;
      if (token == null || token.isEmpty || code == null || code.isEmpty) {
        _showError(
          'Apple did not return complete credentials. Please try again.',
        );
        return;
      }
      await _auth.loginWithApple(
        identityToken: token,
        authorizationCode: code,
        fullName: outcome.fullName,
        email: outcome.email,
        stayLoggedIn: widget.stayLoggedIn,
      );
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
        _showError(
          error.statusCode == 409
              ? 'This Apple ID could not be linked. Please sign in with your existing account.'
              : error.message,
        );
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
  Widget build(BuildContext context) {
    if (!AppleAuthService.isIOS || !_available) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppleSignInButton(
        isLoading: _loading,
        onPressed: widget.enabled && !_loading ? _signIn : null,
      ),
    );
  }
}
