// TODO: wire to backend when endpoint exists
import 'package:flutter/material.dart';
import '../community_local_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../community_theme.dart';

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
    final username = isAnonymous
        ? 'Anonymous'
        : (post['username'] as String? ?? 'user');
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
          color: context.communitySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: context.communityBorder.withValues(alpha: 0.7),
          ),
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
                      color: isAnonymous
                          ? context.communityBorder
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isAnonymous
                          ? '?'
                          : (username.isEmpty
                                ? '?'
                                : username.characters.first.toUpperCase()),
                      style: context.communityBody1.copyWith(
                        color: isAnonymous
                            ? context.communityMuted
                            : Theme.of(context).colorScheme.primary,
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
                          style: context.communityBody1.copyWith(
                            color: context.communityText,
                            fontWeight: FontWeight.w500,
                            fontStyle: isAnonymous
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: context.communityBody2.copyWith(
                            color: context.communityMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((post['topic'] as String? ?? '').isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post['topic'] as String,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.communityBody2.copyWith(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content
            LayoutBuilder(
              builder: (context, constraints) {
                final style = context.communityBody1.copyWith(height: 1.5);
                final layout = TextPainter(
                  text: TextSpan(text: content, style: style),
                  maxLines: 6,
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout(maxWidth: constraints.maxWidth);
                final truncated = layout.didExceedMaxLines;
                layout.dispose();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: style,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (truncated)
                      TextButton(
                        onPressed: onTap,
                        child: const Text('Read more'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Reactions
            Row(
              children: [
                InkWell(
                  onTap: () => CommunityLocalState.instance.toggleLike(post),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    child: _buildReaction(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      count: likes,
                      color: isLiked
                          ? AppColors.danger
                          : context.communityMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    child: _buildReaction(
                      icon: Icons.chat_bubble_outline,
                      count: comments,
                      color: context.communityMuted,
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

  Widget _buildReaction({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
