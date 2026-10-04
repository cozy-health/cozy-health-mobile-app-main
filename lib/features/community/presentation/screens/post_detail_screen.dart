import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../community_theme.dart';
import '../widgets/comment_card.dart';
import '../widgets/report_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  final List<Map<String, dynamic>> _comments = [
    {
      'username': 'mike',
      'isAnonymous': false,
      'timeAgo': '1h',
      'content': 'I\'m glad you shared this. Small wins are real wins.',
      'likes': 5,
      'isLiked': true,
    },
    {
      'username': '',
      'isAnonymous': true,
      'timeAgo': '45m',
      'content': 'This helped me today. Thank you.',
      'likes': 3,
      'isLiked': false,
    },
    {
      'username': 'jordan',
      'isAnonymous': false,
      'timeAgo': '30m',
      'content': 'Same. Thanks for saying it.',
      'likes': 1,
      'isLiked': false,
    },
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

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
            if (!(widget.post['isAnonymous'] as bool? ?? false))
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
                'Report',
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
    final isAnonymous = widget.post['isAnonymous'] as bool? ?? false;
    final username = isAnonymous
        ? 'Anonymous'
        : (widget.post['username'] as String? ?? 'user');
    final timeAgo = widget.post['timeAgo'] as String? ?? 'Just now';
    final content = widget.post['content'] as String? ?? '';
    final likes = widget.post['likes'] as int? ?? 0;
    final isLiked = widget.post['isLiked'] as bool? ?? false;

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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Author
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isAnonymous
                                ? context.communityBorder
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isAnonymous
                                ? '?'
                                : username.substring(0, 1).toUpperCase(),
                            style: context.communityBody1.copyWith(
                              color: isAnonymous
                                  ? context.communityMuted
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAnonymous ? 'Anonymous' : '@$username',
                                style: context.communityBody1.copyWith(
                                  color: context.communityText,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: isAnonymous
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                              Text(
                                timeAgo,
                                style: context.communityBody2.copyWith(
                                  color:
                                      context.communityMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Body
                    Text(
                      content,
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Reactions
                    Row(
                      children: [
                        _buildReactionCard(
                          icon: isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          count: likes,
                          color: isLiked
                              ? AppColors.danger
                              : context.communityMuted,
                        ),
                        SizedBox(width: 12),
                        _buildReactionCard(
                          icon: Icons
                              .sign_language, // using generic icon for support/pray
                          count: 3,
                          color: context.communityMuted,
                        ),
                        SizedBox(width: 12),
                        _buildReactionCard(
                          icon: Icons
                              .emoji_emotions_outlined, // using generic icon for flex/strength
                          count: 2,
                          color: context.communityMuted,
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Divider(color: Theme.of(context).dividerColor),
                    SizedBox(height: 24),

                    // Comments Header
                    Text(
                      'Comments (${_comments.length})',
                      style: context.communityHeading2,
                    ),
                    SizedBox(height: 16),

                    // Comments List
                    ..._comments.map(
                      (comment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CommentCard(
                          comment: comment,
                          onReplyTap: () {
                            _commentFocusNode.requestFocus();
                            final username = comment['username'] as String?;
                            if (username != null && username.isNotEmpty) {
                              _commentController.text = '@$username ';
                            }
                          },
                          onAvatarTap: () {},
                          onLongPress: () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Comment Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'S',
                      style: context.communityBody2.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: context.communityBody1.copyWith(
                          color: context.communityMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_upward, color: Theme.of(context).colorScheme.primary),
                    onPressed: () {
                      if (_commentController.text.isNotEmpty) {
                        _commentController.clear();
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment added.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionCard({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.communityBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(width: 8),
          Text(
            count.toString(),
            style: context.communityBody2.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
