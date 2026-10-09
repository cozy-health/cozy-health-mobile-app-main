// TODO: wire to backend when endpoint exists
import '../../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_scaffold_padding.dart';
import '../community_theme.dart';
import '../widgets/post_card.dart';
import '../community_local_state.dart';
import '../widgets/community_groups.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key, this.posts});

  final List<Map<String, dynamic>>? posts;

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Anxiety',
    'Depression',
    'Trauma',
    'Sleep',
    'Relationships',
    'Self-compassion',
    'Work & Life',
    'Grief & Loss',
  ];

  List<Map<String, dynamic>> get _posts =>
      widget.posts ?? [...CommunityLocalState.instance.posts, ..._defaultPosts];
  final List<Map<String, dynamic>> _defaultPosts = [
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
    {
      'username': '',
      'isAnonymous': true,
      'timeAgo': '4h',
      'content':
          'I don\'t know how to say this out loud yet. But I\'m tired of pretending.',
      'likes': 28,
      'comments': 9,
      'isLiked': false,
      'topic': 'Anxiety',
    },
    {
      'username': 'mike',
      'isAnonymous': false,
      'timeAgo': '6h',
      'content': 'Does anyone else get anxious on Sunday nights? Any tips?',
      'likes': 5,
      'comments': 7,
      'isLiked': false,
      'topic': 'Anxiety',
    },
  ];

  @override
  void initState() {
    super.initState();
    CommunityLocalState.instance.addListener(_refreshLocal);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    CommunityLocalState.instance.removeListener(_refreshLocal);
    super.dispose();
  }

  Animation<double> _createAnimation(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  void _refreshLocal() {
    if (mounted) setState(() {});
  }

  void _showCreateMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(AppRouter.createPost);
                  },
                  child: const Text('Create post'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateCommunityGroupScreen(),
                      ),
                    );
                  },
                  child: const Text('Create new group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(
      backgroundColor: context.communityBackground,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: AppScaffoldPadding.tabScrollBottom(context).bottom,
        ),
        child: FloatingActionButton.small(
          heroTag: 'community-create',
          onPressed: _showCreateMenu,
          tooltip: 'Create post or group',
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: _animatedWidget(
                reduceMotion: reduceMotion,
                animation: _createAnimation(0.0, 0.4),
                offset: const Offset(0, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.push(AppRouter.communitySearch),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 33),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.communityBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Search',
                                  style: context.communityBody2,
                                ),
                              ),
                              const Icon(Icons.search, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(
                        Icons.notifications_outlined,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => context.push(AppRouter.notifications),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Filter Chips
            SizedBox(
              height: 36,
              child: _animatedWidget(
                reduceMotion: reduceMotion,
                animation: _createAnimation(0.1, 0.5),
                offset: const Offset(0, 8),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _selectedFilter == filter;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1)
                              : context.communitySurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : context.communityBorder.withValues(
                                    alpha: 0.7,
                                  ),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: context.communityBody2.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : context.communityText,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 20),

            // Main Content (Feed)
            Expanded(child: _buildFeed(reduceMotion)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool reduceMotion) => EmptyState(
    icon: Icons.waving_hand_outlined,
    title: 'Be the first to share.',
    primaryCtaLabel: 'Share something',
    onPrimaryCta: () => context.push(AppRouter.createPost),
  );
  Widget _buildFeed(bool reduceMotion) {
    final filteredPosts = _selectedFilter == 'All'
        ? _posts
        : _posts.where((p) => p['topic'] == _selectedFilter).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        AppScaffoldPadding.tabScrollBottom(context).bottom,
      ),
      children: [
        Text('General Posts', style: context.communityHeading3),
        const SizedBox(height: 12),
        if (filteredPosts.isEmpty) _buildEmptyState(reduceMotion),
        // Compose Bar
        _animatedWidget(
          reduceMotion: reduceMotion,
          animation: _createAnimation(0.2, 0.7),
          offset: const Offset(0, 12),
          child: GestureDetector(
            onTap: () => context.push(AppRouter.createPost),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: context.communityBorder.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share something...',
                    style: context.communityBody1.copyWith(
                      color: context.communityMuted,
                    ),
                  ),
                  Icon(Icons.edit, size: 20, color: context.communityMuted),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 20),

        ...List.generate(filteredPosts.length, (index) {
          final post = filteredPosts[index];
          // staggered animation for posts
          final start = 0.4 + (index * 0.1);
          final end = start + 0.5;
          final postAnim = _createAnimation(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
          );

          return _animatedWidget(
            reduceMotion: reduceMotion,
            animation: postAnim,
            offset: const Offset(0, 12),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PostCard(
                post: post,
                onTap: () =>
                    context.push(AppRouter.postDetail, extra: {'post': post}),
                onAvatarTap: () {
                  if (!(post['isAnonymous'] as bool? ?? false)) {
                    context.push(
                      AppRouter.userProfile,
                      extra: {'username': post['username']},
                    );
                  }
                },
                onLongPress: () {
                  // show context menu for report etc.
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        const CommunityGroups(),
      ],
    );
  }

  Widget _animatedWidget({
    required bool reduceMotion,
    required Animation<double> animation,
    required Widget child,
    Offset offset = Offset.zero,
  }) {
    if (reduceMotion) return child;

    return FadeTransition(
      opacity: animation,
      child: offset != Offset.zero
          ? SlideTransition(
              position: Tween<Offset>(
                begin: Offset(offset.dx, offset.dy / 100),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            )
          : child,
    );
  }
}
