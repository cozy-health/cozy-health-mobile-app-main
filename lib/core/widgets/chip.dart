import 'package:flutter/material.dart' hide Chip;

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ChipVariant { label, period, topic, tag }

/// Import with an alias when Flutter's Material Chip is also needed.
/// Selection is controlled by the caller; tapping never mutates local state.
class Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;
  final ChipVariant variant;
  final bool compact;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;

  const Chip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.leading,
    this.variant = ChipVariant.label,
    this.compact = false,
    this.backgroundColor,
    this.selectedBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final small = compact || variant == ChipVariant.tag;
    final radius = BorderRadius.circular(small ? 8 : 16);
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : switch (variant) {
            ChipVariant.period => const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 2,
            ),
            ChipVariant.topic => const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            _ => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          };
    final fill = selected
        ? selectedBackgroundColor ??
              (dark ? AppColors.accentSkyDark : AppColors.accentSky)
        : backgroundColor ?? theme.colorScheme.surface;

    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        selected: selected,
        button: onTap != null,
        onTap: onTap,
        child: Material(
          color: fill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : (dark
                        ? AppColors.borderDefaultDark
                        : AppColors.borderDefault),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: radius,
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    SizedBox.square(dimension: 20, child: leading),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.label.copyWith(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
