 import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  int _step = 0;
  bool _isLoading = false;
  String? _emailError;
  String? _otpError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    _emailError = null;
    _otpError = null;
    _passwordError = null;
    _confirmError = null;
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    setState(() {
      _clearErrors();
      _emailError = email.contains('@')
          ? null
          : "That email doesn't look quite right.";
    });
    if (_emailError != null) return;

    setState(() => _isLoading = true);
    showAuthToast(
      context,
      type: AuthToastType.loading,
      title: 'Sending reset code...',
    );

    try {
      await _authService.forgotPassword(email);
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.success,
        title: 'Code sent',
        description: 'Check your inbox.',
      );
      setState(() => _step = 1);
    } on ApiException {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.info,
        title: 'If an account exists, you will receive a code.',
      );
      setState(() => _step = 1);
    } catch (_) {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: "Can't reach the server. Retry?",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyCode() {
    FocusScope.of(context).unfocus();
    if (_otpController.text.length != 6) {
      setState(() => _otpError = "That code doesn't look complete yet.");
      return;
    }
    showAuthToast(context, type: AuthToastType.success, title: 'Code verified');
    setState(() {
      _clearErrors();
      _step = 2;
    });
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text;
    setState(() {
      _clearErrors();
      _passwordError = password.length >= 8
          ? null
          : 'Passwords need at least 8 characters.';
      _confirmError = _confirmController.text == password
          ? null
          : "Passwords don't match yet.";
    });
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _isLoading = true);
    showAuthToast(
      context,
      type: AuthToastType.loading,
      title: 'Resetting password...',
    );

    try {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: password,
      );
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.success,
        title: 'Password reset',
      );
      setState(() => _step = 3);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: e.message.isEmpty
            ? "Couldn't reset password. Retry?"
            : e.message,
      );
    } catch (_) {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: "Couldn't reset password. Retry?",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 3) return _Success(onLogin: () => context.go(AppRouter.login));

    final title = switch (_step) {
      0 => 'Reset your\npassword.',
      1 => 'Check your\ninbox.',
      _ => 'Set a new\npassword.',
    };
    final subtitle = switch (_step) {
      0 => "Enter your email and we'll send you a code to reset it.",
      1 => 'We sent a reset code to ${_emailController.text.trim()}',
      _ => "Make it something you'll remember.",
    };

    return AuthScaffold(
      title: title,
      subtitle: subtitle,
      footer: _step == 0
          ? AuthFooterLink(
              text: 'Remembered it?',
              action: 'Log In',
              onTap: () => context.go(AppRouter.login),
            )
          : null,
      children: [
        if (_step == 0) ...[
          AuthTextField(
            label: 'Email',
            error: _emailError,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 32),
          AuthPrimaryButton(
            text: 'Send Code',
            onPressed: _isLoading ? null : _sendCode,
            isLoading: _isLoading,
          ),
        ],
        if (_step == 1) ...[
          Center(
            child: _OtpInput(
              controller: _otpController,
              hasError: _otpError != null,
            ),
          ),
          if (_otpError != null) ...[
            const SizedBox(height: 12),
            InlineMessage(type: AuthMessageType.error, text: _otpError!),
          ],
          const SizedBox(height: 32),
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : _sendCode,
              child: Text(
                'Did not get it? Resend',
                style: AppTextStyles.linkText.copyWith(
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          AuthPrimaryButton(text: 'Verify Code', onPressed: _verifyCode),
          const SizedBox(height: 24),
          AuthFooterLink(
            text: 'Wrong email?',
            action: 'Change it',
            onTap: () => setState(() => _step = 0),
          ),
        ],
        if (_step == 2) ...[
          AuthTextField(
            label: 'New Password',
            error: _passwordError,
            controller: _passwordController,
            obscure: true,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 12),
          PasswordStrengthBar(password: _passwordController.text),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Confirm New Password',
            error: _confirmError,
            controller: _confirmController,
            obscure: true,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 32),
          AuthPrimaryButton(
            text: 'Reset Password',
            onPressed: _isLoading ? null : _resetPassword,
            isLoading: _isLoading,
          ),
        ],
      ],
    );
  }
}

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;

  const _OtpInput({required this.controller, required this.hasError});

  @override
  Widget build(BuildContext context) {
    PinTheme theme(Color color, double width) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return PinTheme(
        width: 48,
        height: 56,
        textStyle: AppTextStyles.heading2.copyWith(
          color: hasError
              ? AppColors.danger
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: width),
        ),
      );
    }

    return Pinput(
      controller: controller,
      length: 6,
      separatorBuilder: (_) => const SizedBox(width: 8),
      defaultPinTheme: theme(
        hasError
            ? AppColors.danger
            : Theme.of(context).brightness == Brightness.dark
            ? AppColors.borderDark
            : AppColors.borderLight,
        1,
      ),
      focusedPinTheme: theme(
        hasError ? AppColors.danger : Theme.of(context).colorScheme.primary,
        2,
      ),
      errorPinTheme: theme(AppColors.danger, 2),
      onCompleted: (_) {},
    );
  }
}

class _Success extends StatelessWidget {
  final VoidCallback onLogin;

  const _Success({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 96, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: AppColors.success,
                  size: 44,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "You're all set.",
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your password has been reset. Log in with your new one.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              AuthPrimaryButton(text: 'Log In', onPressed: onLogin),
            ],
          ),
        ),
      ),
    );
  }
}
