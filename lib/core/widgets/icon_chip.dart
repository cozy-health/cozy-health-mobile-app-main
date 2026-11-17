import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Compact trigger/tag presentation with caller-controlled selection.
class IconChip extends StatelessWidget {
  final String label;
  final Widget icon;
  final bool selected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? badgeColor;

  const IconChip({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
    this.backgroundColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(8);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: Semantics(
        selected: selected,
        button: onTap != null,
        onTap: onTap,
        child: Material(
          color:
              backgroundColor ??
              (dark ? AppColors.surfaceSubtleDark : AppColors.surfaceSubtle),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: selected
                ? BorderSide(color: theme.colorScheme.primary)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: radius,
            child: ConstrainedBox(
              // 28px at normal scale; grow rather than clip accessibility text.
              constraints: const BoxConstraints(minHeight: 28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 20,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color:
                            badgeColor ??
                            (dark
                                ? AppColors.accentSkyDark
                                : AppColors.accentSky),
                        borderRadius: radius,
                      ),
                      child: IconTheme.merge(
                        data: IconThemeData(
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        child: icon,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
