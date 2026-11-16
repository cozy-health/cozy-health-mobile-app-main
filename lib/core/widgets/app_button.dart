import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/cozy_colors.dart';
import 'app_pressable.dart';

class AppButton extends StatelessWidget {
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

  final String text;
  final VoidCallback? onPressed;
  final bool isOutlined, isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final w = context.cozyColors.wellness;
    final enabled = onPressed != null && !isLoading;
    final foreground = enabled || isLoading
        ? (isOutlined ? c.primary : c.onPrimary)
        : c.onSurfaceVariant;
    return SizedBox(
      width: width ?? double.infinity,
      child: AppPressable(
        label: isLoading ? '$text. Loading' : text,
        onPressed: enabled ? onPressed : null,
        child: Container(
          padding: padding ?? EdgeInsets.all(w.gap),
          decoration: BoxDecoration(
            color: isOutlined
                ? c.surface
                : enabled || isLoading
                ? c.primary
                : Color.alphaBlend(
                    c.onSurface.withValues(alpha: .06),
                    c.surface,
                  ),
            borderRadius: BorderRadius.circular(w.tileRadius),
            border: isOutlined || MediaQuery.highContrastOf(context)
                ? Border.all(color: enabled ? c.primary : c.outline)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: w.sectionSpacing,
                  height: w.sectionSpacing,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                ),
                SizedBox(width: w.contentGap),
              ],
              Flexible(
                child: Text(
                  isLoading ? 'Loading...' : text,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.buttonText.copyWith(color: foreground),
                ),
              ),
              if (!isLoading && trailingIcon != null) ...[
                SizedBox(width: w.small),
                Icon(trailingIcon, size: w.actionIcon, color: foreground),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
