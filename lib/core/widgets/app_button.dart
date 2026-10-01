import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final IconData? trailingIcon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.padding,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : trailingIcon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: AppTextStyles.buttonText.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(trailingIcon, size: 18, color: AppColors.primary),
                      ],
                    )
                  : Text(
                      text,
                      style: AppTextStyles.buttonText.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: Theme.of(
                  context,
                ).disabledColor.withValues(alpha: 0.2),
                disabledForegroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
                padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : trailingIcon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text, style: AppTextStyles.buttonText),
                        const SizedBox(width: 8),
                        Icon(trailingIcon, size: 18, color: AppColors.white),
                      ],
                    )
                  : Text(text, style: AppTextStyles.buttonText),
            ),
    );
  }
}
