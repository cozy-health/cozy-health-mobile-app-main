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
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
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
              const SizedBox(height: 16),
              _buildFeaturedCard(
                username: 'sarahchen',
                content: '"Small wins are still wins."',
                likes: 128,
                comments: 22,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              _buildFeaturedCard(
                username: 'mike',
                content: '"I made it through today."',
                likes: 94,
                comments: 15,
                isPrimary: false,
              ),
              const SizedBox(height: 48),
              
              Text('From the team', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Text(
                'These posts moved us this week.\nWe hope they reach someone who needs them.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard({
    required String username,
    required String content,
    required int likes,
    required int comments,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPrimary ? AppColors.primary.withValues(alpha: 0.2) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary) ...[
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Featured', style: AppTextStyles.body2.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Text(
            content,
            style: AppTextStyles.heading3.copyWith(
              fontFamily: 'Georgia',
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '— @$username',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildReaction(Icons.favorite_border, likes),
              const SizedBox(width: 24),
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
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: AppTextStyles.body2.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
