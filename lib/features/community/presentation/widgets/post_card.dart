import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../community_local_state.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAvatarTap,
    required this.onLongPress,
  });
  final Map<String, dynamic> post;
  final VoidCallback onTap, onAvatarTap, onLongPress;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
    final anonymous = post['isAnonymous'] == true,
        name = post['isAnonymous'] == true
            ? 'Anonymous'
            : (post['username'] as String? ?? 'Community member');
    final raw = post['timeAgo'] as String? ?? '', date = DateTime.tryParse(raw);
    final time = date == null
        ? raw
        : DateFormat.MMMd().add_jm().format(date.toLocal());
    final author = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: w.accentPanel(c),
          ),
          child: anonymous
              ? const Icon(Icons.person_outline_rounded)
              : Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: t.textTheme.titleMedium,
                ),
        ),
        SizedBox(width: w.contentGap),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: t.textTheme.titleSmall),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: t.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return GestureDetector(
      onLongPress: onLongPress,
      child: WellnessPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: anonymous
                      ? author
                      : AppPressable(
                          onPressed: onAvatarTap,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: w.touch),
                            child: author,
                          ),
                        ),
                ),
                AppPressable(
                  label: 'Post options',
                  onPressed: onLongPress,
                  child: SizedBox(
                    width: w.touch,
                    height: w.touch,
                    child: const Icon(Icons.more_horiz_rounded),
                  ),
                ),
              ],
            ),
            if ((post['topic'] as String? ?? '').isNotEmpty) ...[
              SizedBox(height: w.contentGap),
              Text(
                post['topic'] as String,
                style: t.textTheme.labelLarge?.copyWith(
                  color: wellnessAccentInk(context),
                ),
              ),
            ],
            SizedBox(height: w.contentGap),
            if (post['imageUrl'] case final String url)
              Padding(
                padding: EdgeInsets.only(bottom: w.contentGap),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(w.tileRadius),
                  child: Image.network(
                    url,
                    height: 240,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, e, s) =>
                        const Text('Image unavailable. Refresh to try again.'),
                  ),
                ),
              ),
            AppPressable(
              onPressed: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['content'] as String? ?? '',
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  SizedBox(height: w.small),
                  Text(
                    'Read post',
                    style: t.textTheme.labelLarge?.copyWith(
                      color: wellnessAccentInk(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: w.gap),
            Wrap(
              spacing: w.contentGap,
              runSpacing: w.small,
              children: [
                WellnessAction(
                  label: '${post['likes'] ?? 0} likes',
                  selected: post['isLiked'] == true,
                  icon: post['isLiked'] == true
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  onPressed: () =>
                      CommunityLocalState.instance.toggleLike(post),
                ),
                WellnessAction(
                  label: '${post['comments'] ?? 0} comments',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
