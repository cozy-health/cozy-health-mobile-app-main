import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Determinate presentation only. The caller supplies progress in [0, 1].
class ProgressTrack extends StatelessWidget {
  final double value;
  final double height;
  final Color? trackColor;
  final Color? fillColor;
  final String semanticLabel;

  const ProgressTrack({
    super.key,
    required this.value,
    this.height = 4,
    this.trackColor,
    this.fillColor,
    this.semanticLabel = 'Progress',
  }) : assert(value > double.negativeInfinity && value < double.infinity),
       assert(height > 0 && height < double.infinity);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final progress = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height / 2);
    return Semantics(
      label: semanticLabel,
      value: '${(progress * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color:
              trackColor ??
              (dark ? AppColors.borderSubtleDark : AppColors.borderSubtle),
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: progress,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fillColor ?? theme.colorScheme.primary,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
