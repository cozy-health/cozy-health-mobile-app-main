import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold_padding.dart';
import '../widgets/post_card.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

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
    'Sleep',
    'Relationships',
    'Self-compassion',
    'Work & Life',
    'Grief & Loss',
  ];

  final List<Map<String, dynamic>> _posts = [
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _createAnimation(double begin, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    Text(
                      'Community',
                      style: AppTextStyles.heading1.copyWith(fontSize: 28),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: () => context.push(AppRouter.communitySearch),
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
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: AppTextStyles.body2.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.text,
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
            Expanded(
              child: _posts.isEmpty
                  ? _buildEmptyState(reduceMotion)
                  : _buildFeed(reduceMotion),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool reduceMotion) {
    return _animatedWidget(
      reduceMotion: reduceMotion,
      animation: _createAnimation(0.4, 0.9),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                alignment: Alignment.center,
                child: Text('👋', style: TextStyle(fontSize: 48)),
              ),
              SizedBox(height: 24),
              Text('It\'s quiet here.', style: AppTextStyles.heading2),
              SizedBox(height: 8),
              Text(
                'Be the first to share.\nOr just read for now — that\'s welcome too.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              GestureDetector(
                onTap: () => context.push(AppRouter.createPost),
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Share something →',
                    style: AppTextStyles.body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeed(bool reduceMotion) {
    final filteredPosts = _selectedFilter == 'All'
        ? _posts
        : _posts.where((p) => p['topic'] == _selectedFilter).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        AppScaffoldPadding.tabScrollBottom(context).bottom,
      ),
      children: [
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
                  color: AppColors.border.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Share something...',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 20,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
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
              padding: const EdgeInsets.only(bottom: 12),
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
