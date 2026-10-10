import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class InsightCard extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;

  const InsightCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 20,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
