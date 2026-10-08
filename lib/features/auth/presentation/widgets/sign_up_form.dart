import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/password_validation.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../utils/responsive_extensions.dart';

import '../../data/auth_service.dart';

class SignUpFormWidget extends StatefulWidget {
  const SignUpFormWidget({super.key});

  @override
  State<SignUpFormWidget> createState() => _SignUpFormWidgetState();
}

class _SignUpFormWidgetState extends State<SignUpFormWidget> {
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _agreeToTerms = false;
  bool _isLoading = false;

  String _currentPassword = '';
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
    _termsRecognizer = TapGestureRecognizer()..onTap = _showTermsDialog;
  }

  void _onFormChanged() {
    setState(() {
      _currentPassword = _passwordController.text;
    });
  }

  bool get _isFormValid {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    final hasUpperAndLower =
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return username.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        password.length >= 8 &&
        hasUpperAndLower &&
        hasNumber &&
        hasSpecial &&
        password == confirm &&
        _agreeToTerms;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Terms and Conditions', style: AppTextStyles.heading2),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.grey),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(), // Removes default padding to keep it tight
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Last Updated: September 2026\n',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
              Text(
                '1. Introduction\n'
                'Welcome to Cozy Health. By accessing or using our mobile application, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you do not agree to these terms, please do not use our services.\n\n'
                '2. Use of Services\n'
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\n\n'
                '3. Privacy and Data Security\n'
                'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Curabitur pretium tincidunt lacus. Nulla gravida orci a odio. Nullam varius, turpis et commodo pharetra, est eros bibendum elit, nec luctus magna felis sollicitudin mauris.\n\n'
                '4. Medical Disclaimer\n'
                'The content provided in this app is for informational purposes only and is not intended as a substitute for professional medical advice, diagnosis, or treatment. Integer in mauris eu nibh euismod gravida. Duis ac tellus et risus vulputate vehicula. Donec lobortis risus a elit. Etiam tempor.\n\n'
                '5. User Responsibilities\n'
                'Ut aliquam sollicitudin leo. Cras iaculis ultricies nulla. Donec quis dui at dolor tempor interdum. Vivamus quis mi. Phasellus a est. Phasellus magna. In hac habitasse platea dictumst. Curabitur at lacus ac velit ornare lobortis.\n\n'
                '6. Limitation of Liability\n'
                'Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Proin pharetra nonummy pede. Mauris et orci. Aenean nec lorem. In porttitor. Donec laoreet nonummy augue. Suspendisse dui purus, scelerisque at, vulputate vitae, pretium mattis, nunc.\n\n'
                '7. Changes to Terms\n'
                'We reserve the right to modify these terms at any time. Mauris dictum facilisis augue. Mauris placerat eleifend leo. Quisque sit amet est et sapien ullamcorper pharetra. Vestibulum erat wisi, condimentum sed, commodo vitae, ornare sit amet, wisi.',
                style: AppTextStyles.body2,
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            text: 'I Agree',
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _agreeToTerms = true;
              });
            },
            isOutlined: false,
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty) {
      setState(() {
        _usernameError = 'Username is required.';
      });
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError = 'Please enter a valid email address.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _passwordError = 'Password must be at least 8 characters.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match.';
      });
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _generalError = 'Please agree to the terms and conditions.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.register(
        firstname: username,
        lastname: '',
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      context.go(AppRouter.congratulations);
    } on ApiException catch (e) {
      setState(() {
        _generalError = e.message;
      });
    } catch (_) {
      setState(() {
        _generalError = 'Unable to create account. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),

            Center(child: SvgPicture.asset(Assets.svg.logo, height: 48)),

            SizedBox(height: 16),

            if (_generalError != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _generalError!,
                  style: AppTextStyles.body2.copyWith(color: Colors.red),
                ),
              ),
              SizedBox(height: 8),
            ],

            if (_usernameError != null) ...[
              Text(
                _usernameError!,
                style: AppTextStyles.body2.copyWith(color: Colors.red),
              ),
              SizedBox(height: 4),
            ],
            CustomTextField(
              hintText: 'Username',
              controller: _usernameController,
              hasError: _usernameError != null,
            ),

            SizedBox(height: 16),

            if (_emailError != null) ...[
              Text(
                _emailError!,
                style: AppTextStyles.body2.copyWith(color: Colors.red),
              ),
              SizedBox(height: 4),
            ],
            CustomTextField(
              hintText: 'Email Address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              hasError: _emailError != null,
            ),

            SizedBox(height: 16),

            if (_passwordError != null) ...[
              Text(
                _passwordError!,
                style: AppTextStyles.body2.copyWith(color: Colors.red),
              ),
              SizedBox(height: 4),
            ],
            CustomTextField(
              hintText: 'Password',
              isPassword: true,
              controller: _passwordController,
              hasError: _passwordError != null,
            ),

            SizedBox(height: 16),

            if (_confirmPasswordError != null) ...[
              Text(
                _confirmPasswordError!,
                style: AppTextStyles.body2.copyWith(color: Colors.red),
              ),
              SizedBox(height: 4),
            ],
            CustomTextField(
              hintText: 'Confirm Password',
              isPassword: true,
              controller: _confirmPasswordController,
              hasError: _confirmPasswordError != null,
            ),

            SizedBox(height: 16),

            PasswordValidation(password: _currentPassword),

            SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _agreeToTerms = value ?? false;
                            });
                          },
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'By signing up, you are agreeing to our ',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.grey,
                      ),
                      children: [
                        TextSpan(
                          text: 'terms and conditions',
                          style: AppTextStyles.body2.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: _termsRecognizer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            AppButton(
              text: 'Create An Account',
              onPressed: (_isLoading || !_isFormValid)
                  ? null
                  : _handleCreateAccount,
              isLoading: _isLoading,
              isOutlined: false,
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColors.lightGrey, thickness: 1),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    'or',
                    style: AppTextStyles.body2.copyWith(color: AppColors.grey),
                  ),
                ),
                Expanded(
                  child: Divider(color: AppColors.lightGrey, thickness: 1),
                ),
              ],
            ),

            SizedBox(height: 16),

            SizedBox(height: 4),

            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(AppRouter.login),
                child: RichText(
                  text: TextSpan(
                    text: 'Already have an account? ',
                    style: AppTextStyles.body1.copyWith(color: AppColors.grey),
                    children: [
                      TextSpan(
                        text: 'Log In',
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
