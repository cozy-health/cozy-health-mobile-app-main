import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../community_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/post_card.dart';
import '../widgets/report_sheet.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const UserProfileScreen({super.key, required this.extra});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFollowing = false;

  // Mock recent posts
  final List<Map<String, dynamic>> _recentPosts = [
    {
      'username': 'sarahchen',
      'isAnonymous': false,
      'timeAgo': '2h',
      'content':
          'Today was hard but I wanted to share that I\'m still here. Small wins.',
      'likes': 12,
      'comments': 4,
      'isLiked': true,
      'topic': 'Self-compassion',
    },
  ];

  void _showContextMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.link,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text('Copy link'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.notifications_off_outlined,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text('Mute (hide posts)'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(
                Icons.block,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              title: Text('Block user'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.flag_outlined, color: AppColors.danger),
              title: Text(
                'Report user',
                style: context.communityBody1.copyWith(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                ReportSheet.show(
                  context,
                  onSubmit: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted. Thank you.'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.extra['username'] as String? ?? 'user';

    return Scaffold(
      backgroundColor: context.communityBackground,
      appBar: AppBar(
        backgroundColor: context.communityBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_horiz,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _showContextMenu,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    username.substring(0, 1).toUpperCase(),
                    style: context.communityHeading1.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 40,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Name & Join Date
              Text(
                '@$username',
                style: context.communityHeading1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'Joined March 2026',
                style: context.communityBody2.copyWith(
                  color: context.communityMuted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Bio
              Text(
                '"Trying to be kinder to myself."',
                style: context.communityBody1.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatCard('42', 'Posts'),
                  SizedBox(width: 16),
                  _buildStatCard('28', 'Followers'),
                ],
              ),
              SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: _isFollowing ? 'Following' : 'Follow',
                      isOutlined: _isFollowing,
                      onPressed: () {
                        setState(() {
                          _isFollowing = !_isFollowing;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.communityBorder.withValues(alpha: 0.7),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () {
                        context.push(
                          AppRouter.directMessages,
                          extra: {'username': username},
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 48),

              // Recent Posts
              Text('Recent posts', style: context.communityHeading2),
              SizedBox(height: 16),

              ..._recentPosts.map(
                (post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PostCard(
                    post: post,
                    onTap: () => context.push(
                      AppRouter.postDetail,
                      extra: {'post': post},
                    ),
                    onAvatarTap: () {},
                    onLongPress: () {},
                  ),
                ),
              ),

              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String count, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.communityBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          Text(count, style: context.communityHeading2),
          SizedBox(height: 4),
          Text(
            label,
            style: context.communityBody2.copyWith(
              color: context.communityMuted,
            ),
          ),
        ],
      ),
    );
  }
}
