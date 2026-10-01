import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../gen/assets.gen.dart';

enum AuthMessageType { hint, error, success, warning }

enum AuthToastType { success, error, info, warning, loading }

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = true,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBack)
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  color: colorScheme.onSurface,
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                )
              else
                const SizedBox(height: 48),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.heading1.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ...children,
              if (footer != null) ...[
                const SizedBox(height: 24),
                Center(child: footer!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AuthTextField extends StatefulWidget {
  final String label;
  final String? helper;
  final String? error;
  final String? success;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.helper,
    this.error,
    this.success,
    this.keyboardType,
    this.obscure = false,
    this.enabled = true,
    this.onChanged,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = widget.error != null;
    final hasSuccess = widget.success != null && !hasError;
    final borderColor = hasError
        ? AppColors.danger
        : _focusNode.hasFocus
        ? AppColors.borderStrong
        : AppColors.border;
    final message = widget.error ?? widget.success ?? widget.helper;
    final messageType = hasError
        ? AuthMessageType.error
        : hasSuccess
        ? AuthMessageType.success
        : AuthMessageType.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppTextStyles.body2.copyWith(
            color: _focusNode.hasFocus
                ? colorScheme.onSurface
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: FontWeight.w500,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: hasError || _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: _focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 0,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscure && _obscure,
            onChanged: widget.onChanged,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: widget.obscure
                  ? IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        size: 20,
                      ),
                    )
                  : hasSuccess
                  ? const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    )
                  : hasError
                  ? const Icon(Icons.error, color: AppColors.danger, size: 18)
                  : null,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: message == null
              ? const SizedBox(height: 0)
              : Padding(
                  key: ValueKey(message),
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: InlineMessage(type: messageType, text: message),
                ),
        ),
      ],
    );
  }
}

class InlineMessage extends StatelessWidget {
  final AuthMessageType type;
  final String text;

  const InlineMessage({super.key, required this.type, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = switch (type) {
      AuthMessageType.error => AppColors.danger,
      AuthMessageType.success => AppColors.success,
      AuthMessageType.warning => AppColors.warning,
      AuthMessageType.hint =>
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.textSubtleDark
            : AppColors.textSubtleLight,
    };
    final icon = switch (type) {
      AuthMessageType.error => Icons.close,
      AuthMessageType.success => Icons.check,
      AuthMessageType.warning => Icons.warning_amber_rounded,
      AuthMessageType.hint => Icons.info_outline,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body2.copyWith(color: color, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  int get score {
    var value = 0;
    if (password.length >= 8) value++;
    if (password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'))) {
      value++;
    }
    if (password.contains(RegExp(r'[0-9]'))) value++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) value++;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [
      AppColors.danger,
      AppColors.danger,
      AppColors.warning,
      AppColors.primary,
      AppColors.success,
    ];
    final fill = score == 0 ? 0.12 : score / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  children: [
                    Container(height: 4, color: AppColors.lightGrey),
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      widthFactor: fill,
                      child: Container(height: 4, color: colors[score]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                labels[score],
                key: ValueKey(score),
                style: AppTextStyles.body2.copyWith(
                  color: colors[score],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Use 8+ characters with a mix of letters and numbers.',
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSubtleDark
                : AppColors.textSubtleLight,
          ),
        ),
      ],
    );
  }
}

class AuthLogoMark extends StatelessWidget {
  final double size;

  const AuthLogoMark({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 80,
          height: size + 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.08),
                AppColors.primary.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        SvgPicture.asset(Assets.svg.logo, width: size, height: size),
      ],
    );
  }
}

class LegalFooter extends StatefulWidget {
  const LegalFooter({super.key});

  @override
  State<LegalFooter> createState() => _LegalFooterState();
}

class _LegalFooterState extends State<LegalFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/legal/terms');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => context.push('/legal/privacy');
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'By continuing, you agree to our ',
        children: [
          TextSpan(
            text: 'Terms',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy.',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: _privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: AppTextStyles.body2.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textSubtleDark
            : AppColors.textSubtleLight,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }
}

void showAuthToast(
  BuildContext context, {
  required AuthToastType type,
  required String title,
  String? description,
}) {
  final color = switch (type) {
    AuthToastType.success => AppColors.success,
    AuthToastType.error => AppColors.danger,
    AuthToastType.info => AppColors.primary,
    AuthToastType.warning => AppColors.warning,
    AuthToastType.loading => AppColors.borderStrong,
  };
  final icon = switch (type) {
    AuthToastType.success => Icons.check_circle,
    AuthToastType.error => Icons.cancel,
    AuthToastType.info => Icons.info,
    AuthToastType.warning => Icons.warning_amber_rounded,
    AuthToastType.loading => Icons.sync,
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      duration: type == AuthToastType.loading
          ? const Duration(days: 1)
          : const Duration(milliseconds: 3000),
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom > 0
            ? MediaQuery.viewInsetsOf(context).bottom + 16
            : 24,
      ),
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  if (type == AuthToastType.error) {
    HapticFeedback.heavyImpact();
  } else if (type == AuthToastType.success) {
    HapticFeedback.mediumImpact();
  }
}

class AuthFooterLink extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text.rich(
        TextSpan(
          text: '$text\n',
          children: [
            TextSpan(
              text: action,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
        style: AppTextStyles.body2.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;

  const AuthPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: AppButton(
        text: text,
        onPressed: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed!();
              },
        isLoading: isLoading,
        isOutlined: isOutlined,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
