import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum IllustrationPlacement { left, top }

/// A presentation-only card. The caller owns actions and illustration assets.
class IllustratedCard extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? illustration;
  final IllustrationPlacement illustrationPlacement;
  final double illustrationSize;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? backgroundColor;

  const IllustratedCard({
    super.key,
    required this.title,
    this.description,
    this.illustration,
    this.illustrationPlacement = IllustrationPlacement.left,
    this.illustrationSize = 96,
    this.actionLabel,
    this.onAction,
    this.backgroundColor,
  }) : assert(illustrationSize > 0),
       assert(onAction == null || actionLabel != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!, style: theme.textTheme.bodyMedium),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    actionLabel!,
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: onAction == null
                          ? theme.disabledColor
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (dark ? AppColors.surfaceSubtleDark : AppColors.surfaceSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (illustration == null) return copy;
          // Stack the art when a narrow card cannot retain usable copy width.
          final stack =
              illustrationPlacement == IllustrationPlacement.top ||
              constraints.maxWidth < illustrationSize + 136;
          final art = SizedBox.square(
            dimension: illustrationSize,
            child: illustration,
          );
          if (stack) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: art),
                const SizedBox(height: 16),
                copy,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              art,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}
