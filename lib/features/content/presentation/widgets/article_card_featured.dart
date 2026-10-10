import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class ArticleCardFeatured extends StatelessWidget {
  final String title;
  final String readTime;
  final VoidCallback onTap;
  final String? category, imageAsset, preview;

  const ArticleCardFeatured({
    super.key,
    required this.title,
    required this.readTime,
    required this.onTap,
    this.category,
    this.imageAsset,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 180),
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
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FEATURED',
                style: AppTextStyles.body2.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (imageAsset != null) ...[
              SvgPicture.asset(
                imageAsset!,
                height: 80,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 12),
            ],
            if (category != null)
              Text(category!, style: Theme.of(context).textTheme.labelMedium),
            Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (preview != null)
              Text(preview!, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              readTime,
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
