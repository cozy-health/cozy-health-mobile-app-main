import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onLongPress;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAvatarTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isAnonymous = post['isAnonymous'] as bool? ?? false;
    final username = isAnonymous ? 'Anonymous' : (post['username'] as String? ?? 'user');
    final timeAgo = post['timeAgo'] as String? ?? 'Just now';
    final content = post['content'] as String? ?? '';
    final likes = post['likes'] as int? ?? 0;
    final comments = post['comments'] as int? ?? 0;
    final isLiked = post['isLiked'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Row
            GestureDetector(
              onTap: onAvatarTap,
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isAnonymous ? AppColors.border : AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isAnonymous ? '?' : username.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.body1.copyWith(
                        color: isAnonymous ? AppColors.textMuted : AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAnonymous ? 'Anonymous' : '@$username',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w500,
                            fontStyle: isAnonymous ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: AppTextStyles.body2.copyWith(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Content
            Text(
              content,
              style: AppTextStyles.body1.copyWith(height: 1.5),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            // Reactions
            Row(
              children: [
                _buildReaction(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  count: likes,
                  color: isLiked ? AppColors.danger : AppColors.textMuted,
                ),
                const SizedBox(width: 24),
                _buildReaction(
                  icon: Icons.chat_bubble_outline,
                  count: comments,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaction({required IconData icon, required int count, required Color color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: AppTextStyles.body2.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
