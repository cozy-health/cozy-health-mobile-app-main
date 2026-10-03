import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_ui.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _termsError;

  bool get _isFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return _nameController.text.trim().isNotEmpty &&
        email.contains('@') &&
        password.length >= 8 &&
        _confirmController.text == password &&
        _agreeToTerms;
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_clearLiveErrors);
    _emailController.addListener(_clearLiveErrors);
    _passwordController.addListener(_clearLiveErrors);
    _confirmController.addListener(_clearLiveErrors);
  }

  void _clearLiveErrors() {
    setState(() {
      _emailError = null;
      _nameError = null;
      _passwordError = null;
      _confirmError = null;
      _termsError = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _nameError = name.isNotEmpty ? null : 'Enter your name.';
      _emailError = email.contains('@')
          ? null
          : "That email doesn't look quite right.";
      _passwordError = password.length >= 8
          ? null
          : 'Passwords need at least 8 characters.';
      _confirmError = _confirmController.text == password
          ? null
          : "Passwords don't match yet.";
      _termsError = _agreeToTerms
          ? null
          : 'Please agree to the Terms and Privacy Policy to continue.';
    });

    if (_emailError != null ||
        _nameError != null ||
        _passwordError != null ||
        _confirmError != null ||
        _termsError != null) {
      showAuthToast(
        context,
        type: AuthToastType.warning,
        title: _termsError ?? 'Check the highlighted fields.',
      );
      return;
    }

    setState(() => _isLoading = true);
    showAuthToast(
      context,
      type: AuthToastType.loading,
      title: 'Creating your account...',
    );

    try {
      await _authService.register(
        firstname: name,
        lastname: '',
        email: email,
        password: password,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.success,
        title: 'Welcome to Cozy Health.',
        description: "Let's verify your email.",
      );
      context.go(AppRouter.congratulations);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: _friendlyError(e.message),
      );
    } catch (_) {
      if (!mounted) return;
      showAuthToast(
        context,
        type: AuthToastType.error,
        title: "We couldn't reach the server. Retry?",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('exist') || lower.contains('taken')) {
      setState(() {
        _emailError = 'An account already exists with this email.';
      });
      return 'That email is already registered.';
    }
    return message.isEmpty ? 'Unable to create account. Try again?' : message;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your\naccount.',
      subtitle: "Let's start with the basics.",
      footer: AuthFooterLink(
        text: 'Already have an account?',
        action: 'Log In',
        onTap: () => context.go(AppRouter.login),
      ),
      children: [
        AuthTextField(
          label: 'Full Name',
          error: _nameError,
          controller: _nameController,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Email',
          helper: "We'll never share this.",
          error: _emailError,
          success: _emailController.text.contains('@')
              ? 'Email available'
              : null,
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
        const SizedBox(height: 12),
        PasswordStrengthBar(password: _passwordController.text),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Confirm Password',
          error: _confirmError,
          controller: _confirmController,
          obscure: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: _agreeToTerms,
                activeColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() {
                        _agreeToTerms = value ?? false;
                        _termsError = null;
                      }),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: InlineMessage(
                type: AuthMessageType.hint,
                text: 'I agree to the Terms and Privacy Policy.',
              ),
            ),
          ],
        ),
        if (_termsError != null) ...[
          const SizedBox(height: 8),
          InlineMessage(type: AuthMessageType.warning, text: _termsError!),
        ],
        const SizedBox(height: 32),
        AuthPrimaryButton(
          text: 'Create Account',
          onPressed: _isLoading || !_isFormValid ? null : _submit,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
