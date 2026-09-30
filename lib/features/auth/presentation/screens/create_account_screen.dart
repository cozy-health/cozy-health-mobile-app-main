import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/google_sign_in_button.dart';
import '../../../../core/widgets/password_validation.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../utils/screen_util.dart';

import '../../data/auth_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _agreeToTerms = false;
  bool _isLoading = false;

  String _currentPassword = '';
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(() {
      setState(() {
        _currentPassword = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

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

    if (password.length < 6) {
      setState(() {
        _passwordError = 'Password must be at least 6 characters.';
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
    ScreenUtil.init(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _isLoading ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
        ),
        title: Text('Create An Account', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                2.sh,

                Text(
                  'Sign Up',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                2.sh,

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
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  3.sh,
                ],

                if (_usernameError != null) ...[
                  Text(
                    _usernameError!,
                    style: AppTextStyles.body2.copyWith(color: Colors.red),
                  ),
                  1.sh,
                ],

                CustomTextField(
                  hintText: 'Username',
                  controller: _usernameController,
                  hasError: _usernameError != null,
                ),

                2.sh,

                if (_emailError != null) ...[
                  Text(
                    _emailError!,
                    style: AppTextStyles.body2.copyWith(color: Colors.red),
                  ),
                  1.sh,
                ],

                CustomTextField(
                  hintText: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hasError: _emailError != null,
                ),

                2.sh,

                if (_passwordError != null) ...[
                  Text(
                    _passwordError!,
                    style: AppTextStyles.body2.copyWith(color: Colors.red),
                  ),
                  1.sh,
                ],

                CustomTextField(
                  hintText: 'Password',
                  isPassword: true,
                  controller: _passwordController,
                  hasError: _passwordError != null,
                ),

                2.sh,

                PasswordValidation(password: _currentPassword),

                4.sh,

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: _isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'By signing up, you are agreeing to our terms and conditions',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                3.sh,

                AppButton(
                  text: 'Create An Account',
                  onPressed: _isLoading ? null : _handleCreateAccount,
                  isLoading: _isLoading,
                  isOutlined: false,
                ),

                4.sh,

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.lightGrey,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'or',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.lightGrey,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                2.sh,

                GoogleSignInButton(onPressed: () {}),

                2.sh,

                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => context.go(AppRouter.login),
                    child: RichText(
                      text: TextSpan(
                        text: 'Already have an account? ',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.grey,
                        ),
                        children: [
                          TextSpan(
                            text: 'Log In',
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                2.sh,
              ],
            ),
          ),
        ),
      ),
    );
  }
}