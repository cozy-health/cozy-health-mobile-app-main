import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/api/auth_token_service.dart';
import '../../../../core/services/guest_session_service.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _stayLoggedIn = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearErrors);
    _passwordController.addListener(_clearErrors);
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.contains('@') ? null : 'Enter a valid email.';
      _passwordError = password.isNotEmpty ? null : 'Enter your password.';
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    showAuthToast(
      context,
      type: AuthToastType.loading,
      title: 'Logging you in...',
    );

    try {
      await _authService.login(
        email: email,
        password: password,
      );
      if (!mounted) return;

      showAuthToast(
        context,
        type: AuthToastType.success,
        title: 'Welcome back.',
      );
      await GuestSessionService().exitGuestSession();
      final hasCompletedPersonalization = await PersonalizationService()
          .hasCompletedPersonalization();
      if (!mounted) return;
      context.go(
        hasCompletedPersonalization
            ? AppRouter.home
            : AppRouter.personalization,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = _friendlyLoginError(e.message);
      setState(() => _passwordError = message);
      showAuthToast(context, type: AuthToastType.error, title: message);
    } catch (_) {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: "Can't reach the server. Check your connection.",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyLoginError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('password') || lower.contains('credential')) {
      return "That password didn't match. Try again?";
    }
    if (lower.contains('not found') || lower.contains('account')) {
      setState(() {
        _emailError = "We couldn't find an account with that email.";
      });
      return "We couldn't find that account.";
    }
    if (lower.contains('locked') || lower.contains('attempt')) {
      return 'Too many attempts. Try again in 15 minutes.';
    }
    return message.isEmpty ? "That didn't match. Let's try again." : message;
  }

  Future<void> _loginWithBiometric() async {
    final auth = LocalAuthentication();

    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        if (!mounted) return;
        showAuthToast(
          context,
          type: AuthToastType.warning,
          title: "Face ID isn't set up on this device.",
        );
        return;
      }

      final authenticated = await auth.authenticate(
        localizedReason: 'Log in to Cozy Health',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (!authenticated) return;

      final token = await AuthTokenService.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        showAuthToast(
          context,
          type: AuthToastType.warning,
          title: 'Please log in with your password first.',
        );
        return;
      }

      if (mounted) context.go(AppRouter.home);
    } catch (e) {
      debugPrint('Biometric error: $e');
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: "Face ID isn't available right now.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back.',
      subtitle: "It's good to see you again.",
      footer: AuthFooterLink(
        text: 'New here?',
        action: 'Create an account',
        onTap: () => context.go(AppRouter.createAccount),
      ),
      children: [
        AuthTextField(
          label: 'Email',
          error: _emailError,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Password',
          error: _passwordError,
          controller: _passwordController,
          obscure: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _stayLoggedIn,
                activeColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 1.5,
                ),
                fillColor: WidgetStateProperty.all(Colors.transparent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _stayLoggedIn = value ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Stay logged in',
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () => context.push(AppRouter.forgotPassword),
            child: Text(
              'Forgot password?',
              style: AppTextStyles.linkText.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        AuthPrimaryButton(
          text: 'Log In',
          onPressed: _isLoading ? null : _login,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'or',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          ],
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          text: Theme.of(context).platform == TargetPlatform.iOS
              ? 'Log in with Face ID'
              : 'Log in with fingerprint',
          isOutlined: true,
          onPressed: _isLoading ? null : _loginWithBiometric,
        ),
      ],
    );
  }
}
