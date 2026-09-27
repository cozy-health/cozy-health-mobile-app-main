import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppleSignInButton({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey, width: 1.5),
        ),
        child: const Center(
          child: Icon(
            Icons.apple,
            color: AppColors.black,
            size: 30,
          ),
        ),
      ),
    );
  }
}
