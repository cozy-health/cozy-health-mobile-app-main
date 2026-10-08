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

  Widget _loading(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isOutlined
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(width: 12),
      const Text('Loading...'),
    ],
  );
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                ),
                padding: padding ?? const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? _loading(context)
                  : trailingIcon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: AppTextStyles.buttonText.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          trailingIcon,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: AppTextStyles.buttonText.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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
                  ? _loading(context)
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
