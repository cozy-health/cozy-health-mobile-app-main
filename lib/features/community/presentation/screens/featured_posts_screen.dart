import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class FeaturedPostsScreen extends StatelessWidget {
  const FeaturedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Featured', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('This week', style: AppTextStyles.heading2),
              SizedBox(height: 16),
              _buildFeaturedCard(
                context: context,
                username: 'sarahchen',
                content: '"Small wins are still wins."',
                likes: 128,
                comments: 22,
                isPrimary: true,
              ),
              SizedBox(height: 12),
              _buildFeaturedCard(
                context: context,
                username: 'mike',
                content: '"I made it through today."',
                likes: 94,
                comments: 15,
                isPrimary: false,
              ),
              SizedBox(height: 48),

              Text('From the team', style: AppTextStyles.heading2),
              SizedBox(height: 16),
              Text(
                'These posts moved us this week.\nWe hope they reach someone who needs them.',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard({
    required BuildContext context,
    required String username,
    required String content,
    required int likes,
    required int comments,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary) ...[
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Featured',
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
          Text(
            content,
            style: AppTextStyles.heading3.copyWith(
              fontFamily: 'Georgia',
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '— @$username',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              _buildReaction(Icons.favorite_border, likes),
              SizedBox(width: 24),
              _buildReaction(Icons.chat_bubble_outline, comments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReaction(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        SizedBox(width: 6),
        Text(
          count.toString(),
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
