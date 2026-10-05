import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class InlineCTA extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const InlineCTA({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
