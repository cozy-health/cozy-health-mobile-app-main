import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/community_repository.dart';
import '../community_local_state.dart';
import '../widgets/community_groups.dart';
import '../widgets/post_actions.dart';
import '../widgets/post_card.dart';
import '../../../notifications/presentation/widgets/notification_bell.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key, this.posts});
  final List<Map<String, dynamic>>? posts;
  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  late final CommunityRepository _repository;
  String _filter = 'All';
  bool _groups = false;
  static const _topics = [
    'All',
    'Anxiety',
    'Depression',
    'Trauma',
    'Sleep',
    'Work',
    'Self-care',
    'Relationships',
    'Self-compassion',
    'Work & Life',
    'Grief & Loss',
  ];
  @override
  void initState() {
    super.initState();
    _repository = CommunityRepository(
      usePlaceholderData: widget.posts != null ? true : null,
    )..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _repository.removeListener(_refresh);
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
    final posts = (widget.posts ?? _repository.posts)
        .where(
          (p) =>
              CommunityLocalState.instance.isVisible(p) &&
              (_filter == 'All' || p['topic'] == _filter),
        )
        .toList();
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _repository.load,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              w.page,
              w.page,
              w.page,
              w.floatingClearance,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Community',
                      style: t.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const NotificationBell(),
                ],
              ),
              SizedBox(height: w.small),
              const Text('Share at your own pace.'),
              SizedBox(height: w.gap),
              AppPressable(
                label: 'Search community',
                onPressed: () => context.push(AppRouter.communitySearch),
                child: WellnessPanel(
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded),
                      SizedBox(width: w.contentGap),
                      const Expanded(child: Text('Search posts and groups')),
                    ],
                  ),
                ),
              ),
              SizedBox(height: w.gap),
              WellnessSegments(
                labels: const ['Posts', 'Groups'],
                selected: _groups ? 1 : 0,
                keyPrefix: 'community-tab',
                onSelected: (i) => setState(() => _groups = i == 1),
              ),
              SizedBox(height: w.gap),
              if (_groups)
                const CommunityGroups()
              else ...[
                WellnessAction(
                  label: 'Create a post',
                  icon: Icons.add_rounded,
                  filled: true,
                  onPressed: () => context.push(AppRouter.createPost),
                ),
                SizedBox(height: w.gap),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final topic in _topics)
                        Padding(
                          padding: EdgeInsets.only(right: w.small),
                          child: AppPressable(
                            selected: _filter == topic,
                            onPressed: () => setState(() => _filter = topic),
                            child: Container(
                              constraints: BoxConstraints(minHeight: w.touch),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                horizontal: w.contentGap,
                                vertical: w.small,
                              ),
                              decoration: BoxDecoration(
                                color: _filter == topic ? c.primary : c.surface,
                                border: Border.all(color: c.outlineVariant),
                                borderRadius: BorderRadius.circular(
                                  w.tileRadius,
                                ),
                              ),
                              child: Text(
                                topic,
                                style: t.textTheme.labelLarge?.copyWith(
                                  color: _filter == topic
                                      ? c.onPrimary
                                      : c.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: w.sectionSpacing),
                Text('Latest posts', style: t.textTheme.titleLarge),
                SizedBox(height: w.contentGap),
                if (_repository.loading && widget.posts == null)
                  const LinearProgressIndicator(),
                if (_repository.error != null && widget.posts == null) ...[
                  Text(_repository.error!),
                  WellnessAction(
                    label: 'Retry community',
                    onPressed: _repository.load,
                  ),
                ],
                if (posts.isEmpty &&
                    !_repository.loading &&
                    _repository.error == null)
                  const WellnessPanel(
                    child: Text(
                      'No posts here yet. Share something when you’re ready.',
                    ),
                  ),
                for (final post in posts)
                  Padding(
                    padding: EdgeInsets.only(bottom: w.gap),
                    child: PostCard(
                      post: post,
                      onTap: () => context.push(
                        AppRouter.postDetail,
                        extra: {'post': post},
                      ),
                      onAvatarTap: () {
                        if (post['isAnonymous'] != true) {
                          context.push(
                            AppRouter.userProfile,
                            extra: {
                              'username': post['username'],
                              'authorId': post['authorId'],
                            },
                          );
                        }
                      },
                      onLongPress: () => PostActions.show(context, post),
                    ),
                  ),
                SizedBox(height: w.contentGap),
                WellnessPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A little care goes a long way',
                        style: t.textTheme.titleMedium,
                      ),
                      SizedBox(height: w.small),
                      const Text(
                        'Share only what feels comfortable. Respect each other’s privacy. Use a post’s options to report a concern.',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
