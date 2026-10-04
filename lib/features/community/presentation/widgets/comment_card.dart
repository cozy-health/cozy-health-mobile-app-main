import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../community_theme.dart';

class CommentCard extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onReplyTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onLongPress;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onReplyTap,
    required this.onAvatarTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isAnonymous = comment['isAnonymous'] as bool? ?? false;
    final username = isAnonymous ? 'Anonymous' : (comment['username'] as String? ?? 'user');
    final timeAgo = comment['timeAgo'] as String? ?? 'Just now';
    final content = comment['content'] as String? ?? '';
    final likes = comment['likes'] as int? ?? 0;
    final isLiked = comment['isLiked'] as bool? ?? false;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.communitySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.communityBorder.withValues(alpha: 0.7)),
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isAnonymous
                          ? context.communityBorder
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isAnonymous ? '?' : username.substring(0, 1).toUpperCase(),
                      style: context.communityBody2.copyWith(
                        color: isAnonymous
                            ? context.communityMuted
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          isAnonymous ? 'Anonymous' : '@$username',
                          style: context.communityBody2.copyWith(
                            color: context.communityText,
                            fontWeight: FontWeight.w500,
                            fontStyle: isAnonymous ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                        Text(
                          ' · $timeAgo',
                          style: context.communityBody2.copyWith(
                            color: context.communityMuted,
                          ),
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
              style: context.communityBody1.copyWith(height: 1.5),
            ),
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked ? AppColors.danger : context.communityMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      likes.toString(),
                      style: context.communityBody2.copyWith(
                        color: isLiked ? AppColors.danger : context.communityMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: onReplyTap,
                  child: Text(
                    'Reply',
                    style: context.communityBody2.copyWith(
                      color: context.communityMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
