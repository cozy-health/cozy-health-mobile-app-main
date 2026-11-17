import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/theme/app_text_styles.dart';

class InlineCTA extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const InlineCTA({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppSurface.tint(
            context,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(12),
          border: AppSurface.border(context),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
