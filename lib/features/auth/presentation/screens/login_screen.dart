import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/google_sign_in_button.dart';

import '../../../../utils/responsive_extensions.dart';
import '../../../../utils/screen_util.dart';

import '../../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailError =
            "Please enter a valid email address.";
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _passwordError =
            "Password is required.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = response['user'];

      final hasProfile =
          user != null &&
          user['profile'] != null;

      if (hasProfile) {
        context.go(AppRouter.home);
      } else {
        context.go(AppRouter.personalization);
      }
    } on ApiException catch (e) {
      setState(() {
        _generalError = e.message;
      });
    } catch (e) {
      setState(() {
        _generalError =
            'Unable to login right now. Please try again.';
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
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.black,
          ),
        ),
        title: Text(
          'Log In',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 6.w,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                2.sh,

                Text(
                  'Welcome Back',
                  style:
                      AppTextStyles.heading1.copyWith(
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
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Text(
                      _generalError!,
                      style:
                          AppTextStyles.body2.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  3.sh,
                ],

                if (_emailError != null) ...[
                  Text(
                    _emailError!,
                    style:
                        AppTextStyles.body2.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  1.sh,
                ],

                CustomTextField(
                  hintText: 'Email Address',
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  hasError: _emailError != null,
                ),

                3.sh,

                if (_passwordError != null) ...[
                  Text(
                    _passwordError!,
                    style:
                        AppTextStyles.body2.copyWith(
                      color: Colors.red,
                    ),
                  ),
                  1.sh,
                ],

                CustomTextField(
                  hintText: 'Password',
                  isPassword: true,
                  controller: _passwordController,
                  hasError:
                      _passwordError != null,
                ),

                2.sh,

                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize:
                          MaterialTapTargetSize
                              .shrinkWrap,
                    ),
                    child: Text(
                      'Forgot your password ?',
                      style:
                          AppTextStyles.linkText
                              .copyWith(
                        decoration:
                            TextDecoration
                                .underline,
                      ),
                    ),
                  ),
                ),

                4.sh,

                AppButton(
                  text: _isLoading
                      ? 'Logging In...'
                      : 'Log In',
                  onPressed:
                      _isLoading
                          ? null
                          : _handleLogin,
                  isOutlined: false,
                ),

                4.sh,

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color:
                            AppColors.lightGrey,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(
                        horizontal: 4.w,
                      ),
                      child: Text(
                        'or',
                        style:
                            AppTextStyles.body2
                                .copyWith(
                          color:
                              AppColors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color:
                            AppColors.lightGrey,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                4.sh,

                GoogleSignInButton(
                  onPressed: () {},
                ),

                2.sh,

                Center(
                  child: TextButton(
                    onPressed: () => context.go(
                      AppRouter.createAccount,
                    ),
                    child: RichText(
                      text: TextSpan(
                        text:
                            'Don\'t have an account? ',
                        style:
                            AppTextStyles.body1
                                .copyWith(
                          color:
                              AppColors.grey,
                        ),
                        children: [
                          TextSpan(
                            text: 'Sign up',
                            style:
                                AppTextStyles
                                    .body1
                                    .copyWith(
                              color:
                                  AppColors
                                      .primary,
                              fontWeight:
                                  FontWeight
                                      .w600,
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