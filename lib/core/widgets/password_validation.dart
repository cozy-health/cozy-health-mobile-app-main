import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PasswordValidation extends StatelessWidget {
  final String password;

  const PasswordValidation({
    super.key,
    required this.password,
  });

  bool get hasMinLength => password.length >= 8;
  bool get hasUpperAndLowerCase => 
      password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'));
  bool get hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Protect your account by creating a strong password',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 12),
        _buildValidationItem('A minimum of 8 characters', hasMinLength),
        const SizedBox(height: 8),
        _buildValidationItem('Lower and upper case letters', hasUpperAndLowerCase),
        const SizedBox(height: 8),
        _buildValidationItem('At least 1 number', hasNumber),
        const SizedBox(height: 8),
        _buildValidationItem('At least 1 character', hasSpecialChar),
      ],
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isValid ? Colors.green : Colors.transparent,
            border: isValid ? null : Border.all(color: AppColors.grey, width: 1.5),
          ),
          child: isValid
              ? const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTextStyles.body2.copyWith(
            color: isValid ? Colors.green : AppColors.grey,
          ),
        ),
      ],
    );
  }
}