import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
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

  bool get _isValid =>
      _emailController.text.trim().contains('@') &&
      _passwordController.text.isNotEmpty;

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
      _emailError = email.contains('@')
          ? null
          : "That email doesn't look quite right.";
      _passwordError = password.isNotEmpty ? null : 'This field is required.';
    });

    if (_emailError != null || _passwordError != null) return;

    setState(() => _isLoading = true);
    showAuthToast(
      context,
      type: AuthToastType.loading,
      title: 'Logging you in...',
    );

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      if (!mounted) return;

      showAuthToast(
        context,
        type: AuthToastType.success,
        title: 'Welcome back.',
      );
      final user = response['user'];
      final hasProfile = user != null && user['profile'] != null;
      context.go(hasProfile ? AppRouter.home : AppRouter.personalization);
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
                activeColor: AppColors.primary,
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
              style: AppTextStyles.body2.copyWith(color: AppColors.text),
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
          onPressed: _isLoading || !_isValid ? null : _login,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: AppTextStyles.body2),
            ),
            const Expanded(child: Divider(color: AppColors.border)),
          ],
        ),
        const SizedBox(height: 24),
        AuthPrimaryButton(
          text: Theme.of(context).platform == TargetPlatform.iOS
              ? 'Log in with Face ID'
              : 'Log in with fingerprint',
          isOutlined: true,
          onPressed: () => showAuthToast(
            context,
            type: AuthToastType.warning,
            title: "Biometric login isn't available yet.",
            description: 'Use your password for now.',
          ),
        ),
      ],
    );
  }
}
