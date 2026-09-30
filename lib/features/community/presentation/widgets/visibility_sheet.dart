import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

enum PostVisibility { public, followers, anonymous }

class VisibilitySheet extends StatelessWidget {
  final PostVisibility currentVisibility;
  final ValueChanged<PostVisibility> onSelect;

  const VisibilitySheet({
    super.key,
    required this.currentVisibility,
    required this.onSelect,
  });

  static void show(BuildContext context, {
    required PostVisibility currentVisibility,
    required ValueChanged<PostVisibility> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => VisibilitySheet(
        currentVisibility: currentVisibility,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Who can see this?', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          _buildOption(
            context,
            title: 'Public',
            subtitle: 'Anyone here can see',
            value: PostVisibility.public,
          ),
          _buildOption(
            context,
            title: 'Followers only',
            subtitle: 'Only people who follow you',
            value: PostVisibility.followers,
          ),
          _buildOption(
            context,
            title: 'Anonymous',
            subtitle: 'Post without your name',
            value: PostVisibility.anonymous,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Note: Moderators can always see your username for safety.',
              style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required PostVisibility value,
  }) {
    final isSelected = currentVisibility == value;
    return InkWell(
      onTap: () {
        onSelect(value);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w500)),
                  Text(subtitle, style: AppTextStyles.body2.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
