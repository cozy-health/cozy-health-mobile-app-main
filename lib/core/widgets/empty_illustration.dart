import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

/// An optional action belongs to the caller; existing empty states are untouched.
class EmptyIllustration extends StatelessWidget {
  final String heading;
  final String message;
  final Widget? illustration;
  final IconData icon;
  final double illustrationSize;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyIllustration({
    super.key,
    required this.heading,
    required this.message,
    this.illustration,
    this.icon = Icons.notifications_none,
    this.illustrationSize = 160,
    this.actionLabel,
    this.onAction,
  }) : assert(illustrationSize > 0),
       assert(onAction == null || actionLabel != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: illustrationSize,
              child:
                  illustration ??
                  Icon(
                    icon,
                    size: illustrationSize,
                    color: dark
                        ? AppColors.borderDefaultDark
                        : AppColors.borderDefault,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              heading,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              AppButton(text: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
