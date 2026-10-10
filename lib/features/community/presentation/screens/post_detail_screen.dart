// TODO: wire to backend when endpoint exists
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../community_theme.dart';
import '../widgets/comment_card.dart';
import '../community_local_state.dart';
import 'comments_screen.dart';
import '../widgets/post_actions.dart';

class PostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.commentsOnly = false,
  });
  final bool commentsOnly;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  Map<String, dynamic>? _replyTo;

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
  void initState() {
    super.initState();
    if ((widget.post['comments'] as int? ?? 0) == 0) _comments.clear();
    final saved = CommunityLocalState.instance.thread(widget.post, _comments);
    _comments.clear();
    _comments.addAll(saved);
    CommunityLocalState.instance.addListener(_refreshThread);
  }

  void _refreshThread() {
    if (mounted) {
      setState(() {
        final thread = CommunityLocalState.instance.thread(
          widget.post,
          const [],
        );
        _comments.clear();
        _comments.addAll(thread);
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    CommunityLocalState.instance.removeListener(_refreshThread);
    super.dispose();
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
        title: Text(widget.commentsOnly ? 'Comments' : 'Post'),
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
            onPressed: () => PostActions.show(context, widget.post),
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
                    if (!widget.commentsOnly) ...[
                      // Post Author
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isAnonymous
                                  ? context.communityBorder
                                  : Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              isAnonymous
                                  ? '?'
                                  : (username.isEmpty
                                        ? '?'
                                        : username.characters.first
                                              .toUpperCase()),
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
                                    color: context.communityMuted,
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
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildReactionCard(
                            icon: isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            count: likes,
                            color: isLiked
                                ? Theme.of(context).colorScheme.error
                                : context.communityMuted,
                            onTap: () => CommunityLocalState.instance
                                .toggleLike(widget.post),
                          ),
                          _buildReactionCard(
                            icon: Icons.comment_outlined,
                            count: _comments.length,
                            color: context.communityMuted,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CommentsScreen(post: widget.post),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      Divider(color: Theme.of(context).dividerColor),
                      SizedBox(height: 24),

                      // Comments Header
                    ],
                    Text(
                      'Comments (${_comments.length})',
                      style: context.communityHeading2,
                    ),
                    SizedBox(height: 16),

                    // Comments List
                    if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No comments yet. Be the first.'),
                      ),
                    ...(widget.commentsOnly ? _comments : _comments.take(3))
                        .map(
                          (comment) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                CommentCard(
                                  comment: comment,
                                  onReplyTap: () {
                                    setState(() => _replyTo = comment);
                                    _commentFocusNode.requestFocus();
                                    final username =
                                        comment['username'] as String?;
                                    if (username != null &&
                                        username.isNotEmpty) {
                                      _commentController.text = '@$username ';
                                    }
                                  },
                                  onAvatarTap: () {},
                                  onLongPress: () {},
                                ),
                                for (final reply
                                    in (comment['replies'] as List? ??
                                        const []))
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 28,
                                      top: 8,
                                    ),
                                    child: CommentCard(
                                      comment: Map<String, dynamic>.from(
                                        reply as Map,
                                      ),
                                      onReplyTap: () {
                                        setState(() => _replyTo = comment);
                                        _commentFocusNode.requestFocus();
                                      },
                                      onAvatarTap: () {},
                                      onLongPress: () {},
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    if (!widget.commentsOnly)
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CommentsScreen(post: widget.post),
                          ),
                        ),
                        child: const Text('View all comments'),
                      ),
                  ],
                ),
              ),
            ),

            // Comment Input
            if (_replyTo != null)
              ListTile(
                dense: true,
                title: Text(
                  'Replying to ${_replyTo!['isAnonymous'] == true ? 'Anonymous' : _replyTo!['username']}',
                ),
                trailing: IconButton(
                  tooltip: 'Cancel reply',
                  onPressed: () => setState(() => _replyTo = null),
                  icon: const Icon(Icons.close),
                ),
              ),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
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
                    icon: Icon(
                      Icons.arrow_upward,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      if (_commentController.text.trim().isNotEmpty) {
                        final thread = CommunityLocalState.instance.thread(
                          widget.post,
                          const [],
                        );
                        CommunityLocalState.instance.addComment(
                          widget.post,
                          thread,
                          _commentController.text,
                          parent: _replyTo,
                        );
                        setState(() {
                          _comments.clear();
                          _comments.addAll(thread);
                          _replyTo = null;
                        });
                        _commentController.clear();
                        FocusScope.of(context).unfocus();
                        AppSnackbar.show(
                          context,
                          AppSnackbar.fromLegacy(
                            content: Text('Comment added.'),
                          ),
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
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.communityBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
