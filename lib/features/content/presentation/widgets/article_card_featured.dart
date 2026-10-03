import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ArticleCardFeatured extends StatelessWidget {
  final String title;
  final String readTime;
  final VoidCallback onTap;

  const ArticleCardFeatured({
    super.key,
    required this.title,
    required this.readTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              const Color(0xFFE8A050).withValues(alpha: 0.05), // warm orange
            ],
          ),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FEATURED',
                style: AppTextStyles.body2.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(fontSize: 20, color: AppColors.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              readTime,
              style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
