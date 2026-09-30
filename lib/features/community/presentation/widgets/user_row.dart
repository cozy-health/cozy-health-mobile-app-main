import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTap;
  final VoidCallback onFollowToggle;

  const UserRow({
    super.key,
    required this.user,
    required this.onTap,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username'] as String? ?? 'user';
    final bio = user['bio'] as String?;
    final isFollowing = user['isFollowing'] as bool? ?? false;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                username.substring(0, 1).toUpperCase(),
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@$username',
                    style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bio,
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onFollowToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isFollowing ? Colors.transparent : AppColors.primary,
                  border: isFollowing ? Border.all(color: AppColors.border) : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isFollowing ? AppColors.text : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
