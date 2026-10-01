import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_scaffold_padding.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../features/settings/data/profile_repository.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../features/notifications/data/notification_repository.dart';
import '../../../../gen/assets.gen.dart';

enum HomeDashboardState {
  returningUser,
  firstTime,
  partialData,
  loading,
  offline,
  error,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.state = HomeDashboardState.returningUser});

  final HomeDashboardState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  int _affirmationIndex = 0;

  final MoodRepository _moodRepo = MoodRepository();

  final List<String> _affirmations = const [
    "You're doing great.\nSmall steps count.",
    "It's okay to rest.",
    "Feelings are visitors.\nLet them come and go.",
  ];

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!MediaQuery.of(context).disableAnimations) {
        _entranceController.forward();
      } else {
        _entranceController.value = 1;
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == HomeDashboardState.error) {
      return _HomeErrorView(onRetry: () {});
    }

    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: StreamBuilder<List<MoodEntry>>(
          stream: _moodRepo.watchMoodEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const _HomeSkeleton();
            }

            final entries = snapshot.data ?? [];
            final isEmpty = entries.isEmpty;

            // Determine state dynamically
            final dynamicState = isEmpty
                ? HomeDashboardState.firstTime
                : HomeDashboardState.returningUser;

            // Compute streak
            final now = DateTime.now();
            int streak = 0;
            // A simple streak logic for last 7 days (mocking a real calculation)
            // Real logic would group by day and count consecutive days backwards
            if (entries.isNotEmpty) {
              streak = 1; // Simplified for now
            }

            // Recent 2 entries
            final recentEntries = entries.take(2).toList();
            final hasMoodToday =
                entries.isNotEmpty &&
                entries.first.createdAt.day == now.day &&
                entries.first.createdAt.month == now.month &&
                entries.first.createdAt.year == now.year;

            return Semantics(
              label:
                  'Home dashboard loaded. $streak day streak. ${recentEntries.length} recent entries.',
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  AppScaffoldPadding.tabScrollBottom(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dynamicState == HomeDashboardState.offline) ...[
                      _OfflineBanner(onRetry: () {}),
                      const SizedBox(height: 16),
                    ],
                    _AnimatedIn(
                      controller: _entranceController,
                      interval: const Interval(
                        0,
                        .35,
                        curve: Curves.easeOutCubic,
                      ),
                      child: const _Header(),
                    ),
                    const SizedBox(height: 24),
                    if (dynamicState == HomeDashboardState.firstTime)
                      _AnimatedIn(
                        controller: _entranceController,
                        interval: const Interval(
                          .14,
                          .58,
                          curve: Curves.easeOutCubic,
                        ),
                        yOffset: 16,
                        child: const _FirstTimeHero(),
                      )
                    else
                      _AnimatedIn(
                        controller: _entranceController,
                        interval: const Interval(
                          .14,
                          .58,
                          curve: Curves.easeOutCubic,
                        ),
                        yOffset: 16,
                        child: _MoodHero(hasMoodToday: hasMoodToday),
                      ),
                    const SizedBox(height: 16),
                    _AnimatedIn(
                      controller: _entranceController,
                      interval: const Interval(
                        .28,
                        .68,
                        curve: Curves.easeOutCubic,
                      ),
                      yOffset: 12,
                      child: _StatsRow(isEmpty: isEmpty, streak: streak),
                    ),
                    const SizedBox(height: 32),
                    if (dynamicState == HomeDashboardState.firstTime)
                      _FirstTimeInfo(controller: _entranceController)
                    else ...[
                      _SectionHeader(
                        title: 'This week',
                        action: 'See all',
                        onAction: () => context.push(AppRouter.moodHistory),
                      ),
                      const SizedBox(height: 12),
                      _AnimatedIn(
                        controller: _entranceController,
                        interval: const Interval(
                          .48,
                          .86,
                          curve: Curves.easeOutCubic,
                        ),
                        yOffset: 10,
                        child: _MoodChart(compact: entries.length < 3),
                      ),
                      const SizedBox(height: 32),
                      _SectionHeader(
                        title: 'Recent entries',
                        action: 'See all',
                        onAction: () => context.push(AppRouter.moodHistory),
                      ),
                      const SizedBox(height: 12),
                      if (recentEntries.isEmpty)
                        const _EmptyCard(
                          icon: Icons.edit_note,
                          title: 'Your first entry will show here',
                          subtitle: 'Notes stay private and easy to revisit.',
                        )
                      else
                        ...recentEntries.asMap().entries.map(
                          (entry) => Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == recentEntries.length - 1
                                  ? 0
                                  : 8,
                            ),
                            child: _AnimatedIn(
                              controller: _entranceController,
                              interval: Interval(
                                .64 + (entry.key * .07),
                                1,
                                curve: Curves.easeOutCubic,
                              ),
                              yOffset: 12,
                              child: _EntryCard(entry: entry.value),
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    _AnimatedIn(
                      controller: _entranceController,
                      interval: const Interval(
                        .82,
                        1,
                        curve: Curves.easeOutCubic,
                      ),
                      yOffset: 12,
                      child: _AffirmationCard(
                        text: _affirmations[_affirmationIndex],
                        index: _affirmationIndex,
                        count: _affirmations.length,
                        onSwipe: (direction) {
                          setState(() {
                            _affirmationIndex =
                                (_affirmationIndex + direction) %
                                _affirmations.length;
                            if (_affirmationIndex < 0) {
                              _affirmationIndex = _affirmations.length - 1;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: ProfileRepository().watchProfile(),
      initialData: LocalDbService.instance.getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final profileName = profile?.name.trim();
        final name = profileName == null || profileName.isEmpty
            ? 'there'
            : profileName;
        final avatarUrl = profile?.avatarUrl;

        final hour = DateTime.now().hour;
        final greeting = hour < 5
            ? 'Still up,'
            : hour < 12
            ? 'Good morning,'
            : hour < 18
            ? 'Good afternoon,'
            : 'Good evening,';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$name.',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Notifications',
              child: StreamBuilder<List<AppNotification>>(
                stream: NotificationRepository().watchNotifications(),
                builder: (context, notifSnapshot) {
                  final unreadCount = (notifSnapshot.data ?? [])
                      .where((n) => !n.read)
                      .length;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: AppColors.text,
                        ),
                        onPressed: () => context.push(AppRouter.notifications),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: 'Open profile',
              child: GestureDetector(
                onTap: () => context.push(AppRouter.editProfile),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl) as ImageProvider
                      : AssetImage(Assets.png.profilePic.path),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MoodHero extends StatefulWidget {
  const _MoodHero({required this.hasMoodToday});

  final bool hasMoodToday;

  @override
  State<_MoodHero> createState() => _MoodHeroState();
}

class _MoodHeroState extends State<_MoodHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final borderOpacity = reduceMotion
            ? .15
            : .08 + (_pulseController.value * .07);
        return _WarmCard(
          color: AppColors.primarySubtle,
          borderColor: AppColors.primary.withValues(alpha: borderOpacity),
          minHeight: 140,
          child: child!,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hasMoodToday
                ? 'You logged: 😊 Good.\nWant to add a note?'
                : 'How are you feeling\nright now?',
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.text,
              height: 1.18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: widget.hasMoodToday
                ? 'Add a note to today mood'
                : 'Log your mood',
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push(AppRouter.moodFeeling),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.hasMoodToday ? 'Add a note' : 'Log your mood',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstTimeHero extends StatelessWidget {
  const _FirstTimeHero();

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: AppColors.primarySubtle,
      borderColor: AppColors.primary.withValues(alpha: .15),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.self_improvement,
              color: AppColors.primary.withValues(alpha: .78),
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Cozy Health.',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            "Let's start with how\nyou're feeling today.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.push(AppRouter.moodFeeling),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log your first mood'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.isEmpty, required this.streak});

  final bool isEmpty;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            title: isEmpty ? 'Start your\nstreak' : '$streak',
            subtitle: isEmpty ? '' : 'day streak',
            isEmpty: isEmpty,
            onTap: isEmpty
                ? () => context.push(AppRouter.moodFeeling)
                : () => _pushPage(context, const StreakDetailScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: '😊',
            title: isEmpty ? 'No moods\nthis week' : 'Good',
            subtitle: isEmpty ? '' : 'This week',
            isEmpty: isEmpty,
            onTap: isEmpty
                ? () => context.push(AppRouter.moodFeeling)
                : () => _pushPage(context, const InsightsScreen()),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEmpty,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final bool isEmpty;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title $subtitle',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isEmpty
                  ? AppColors.borderStrong
                  : AppColors.border.withValues(alpha: .7),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  color: isEmpty ? AppColors.textMuted : AppColors.text,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
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

class _MoodChart extends StatelessWidget {
  const _MoodChart({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const _EmptyCard(
        icon: Icons.show_chart,
        title: 'Log 3 moods to see trends',
        subtitle: 'Keep logging. Your patterns will appear here gently.',
      );
    }

    const values = [36.0, 52.0, 76.0, 92.0, 70.0, 48.0, 34.0];
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GestureDetector(
      onTap: () => _pushPage(context, const InsightsScreen()),
      child: _WarmCard(
        color: AppColors.surfaceElevated,
        minHeight: 120,
        child: Semantics(
          label: 'This week mood chart. Good was the most common mood.',
          child: Column(
            children: [
              SizedBox(
                height: 72,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final value in values)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: .42,
                            child: Container(
                              height: value,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: .78),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final day in days)
                    Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final MoodEntry entry;

  String _getEmojiForMood(String mood) {
    if (mood == 'Good') return '\u{1F60A}';
    if (mood == 'Calm') return '\u{1F60C}';
    if (mood == 'Okay') return '\u{1F610}';
    if (mood == 'Low') return '\u{1F614}';
    if (mood == 'Anxious') return '\u{1F630}';
    if (mood == 'Angry') return '\u{1F621}';
    return '\u{1F60A}';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year &&
        now.month == time.month &&
        now.day == time.day) {
      return 'Today, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.month}/${time.day}, ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${entry.mood}, ${_formatTime(entry.createdAt)}',
      child: InkWell(
        onTap: () => context.push(AppRouter.moodDetail, extra: entry),
        borderRadius: BorderRadius.circular(16),
        child: _WarmCard(
          color: AppColors.surfaceElevated,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                _getEmojiForMood(entry.mood),
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mood,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(entry.createdAt),
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AffirmationCard extends StatelessWidget {
  const _AffirmationCard({
    required this.text,
    required this.index,
    required this.count,
    required this.onSwipe,
  });

  final String text;
  final int index;
  final int count;
  final ValueChanged<int> onSwipe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < 0) onSwipe(1);
        if ((details.primaryVelocity ?? 0) > 0) onSwipe(-1);
      },
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affirmation copied privately.')),
        );
      },
      child: _WarmCard(
        color: AppColors.warmYellow.withValues(alpha: .08),
        borderColor: AppColors.warmYellow.withValues(alpha: .2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💛', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.text,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: List.generate(
                count,
                (dot) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 6),
                  width: dot == index ? 16 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dot == index
                        ? AppColors.warmYellow
                        : AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(10),
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

class _FirstTimeInfo extends StatelessWidget {
  const _FirstTimeInfo({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.bar_chart_rounded, 'Your mood patterns', 'Over time, gently'),
      (Icons.edit_note_rounded, 'Journal entries', 'A private space'),
      (
        Icons.chat_bubble_outline_rounded,
        'AI companion',
        'Always here to listen',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: "What you'll find here"),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 8),
            child: _AnimatedIn(
              controller: controller,
              interval: Interval(.5 + (i * .08), 1, curve: Curves.easeOutCubic),
              yOffset: 12,
              child: _InfoCard(
                icon: items[i].$1,
                title: items[i].$2,
                subtitle: items[i].$3,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: AppColors.warning.withValues(alpha: .12),
      borderColor: AppColors.warning.withValues(alpha: .3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline. Showing your last data.",
              style: AppTextStyles.body2.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Re-check connection',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonLine(width: 130),
          const SizedBox(height: 8),
          Row(
            children: const [
              _SkeletonLine(width: 110, height: 24),
              Spacer(),
              _SkeletonCircle(size: 40),
            ],
          ),
          const SizedBox(height: 28),
          const _SkeletonBox(height: 140, radius: 20),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _SkeletonBox(height: 96, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(height: 96, radius: 16)),
            ],
          ),
          const SizedBox(height: 32),
          const _SkeletonLine(width: 100),
          const SizedBox(height: 12),
          const _SkeletonBox(height: 120, radius: 16),
          const SizedBox(height: 32),
          const _SkeletonLine(width: 130),
          const SizedBox(height: 12),
          const _SkeletonBox(height: 72, radius: 16),
          const SizedBox(height: 8),
          const _SkeletonBox(height: 72, radius: 16),
        ],
      ),
    );
  }
}

class _HomeErrorView extends StatelessWidget {
  const _HomeErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  "We couldn't load\nyour home screen.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Check your connection\nand try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Try again'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const moods = {
      3: '😊',
      5: '😐',
      8: '😊',
      11: '😔',
      16: '😊',
      17: '😊',
      22: '😊',
      24: '😐',
    };

    return _DetailScaffold(
      title: 'Mood history',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'September 2026',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(child: Text(day, style: AppTextStyles.body2)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final mood = moods[day];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        mood == null
                            ? 'Log a mood for this day?'
                            : 'Mood detail for September $day',
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      mood ?? '$day',
                      style: TextStyle(
                        fontSize: mood == null ? 13 : 20,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Legend',
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            '😊 Good   😐 Okay   😔 Low',
            style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          _WarmCard(
            color: AppColors.surfaceElevated,
            child: Text(
              '12 entries\nMost common: 😊 Good\nStreak: 4 days',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.text,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreakDetailScreen extends StatelessWidget {
  const StreakDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Streak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 44)),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '7',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 48,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'day streak',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.text),
                ),
                const SizedBox(height: 18),
                Text(
                  "You've logged your\nmood 7 days in a row.\nKeep it going.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _WarmCard(
            color: AppColors.surfaceElevated,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                30,
                (index) => Icon(
                  index < 23 ? Icons.circle : Icons.circle_outlined,
                  size: 16,
                  color: index < 23
                      ? AppColors.primary
                      : AppColors.borderStrong,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Milestones',
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 12),
          const _MilestoneCard(text: '7-day streak', value: 'Achieved!'),
          const SizedBox(height: 8),
          const _MilestoneCard(text: '30-day streak', value: '5 to go'),
          const SizedBox(height: 8),
          const _MilestoneCard(text: '100-day streak', value: '93 to go'),
        ],
      ),
    );
  }
}

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: 'Insights',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'This week',
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You felt calmer\nthan last week.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _WarmCard(
            color: AppColors.surfaceElevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood trend',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                const _SimpleAreaChart(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _BreakdownCard(title: 'Most common', value: '😊 Good'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _BreakdownCard(
                  title: 'Most common trigger',
                  value: 'Work',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'What helped',
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            '• Breathing (4 times)\n• Journaling (2 times)',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Gentle note',
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            "You logged 12 entries this week. That's a lot of self-awareness.",
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.text, required this.value});

  final String text;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: AppColors.surfaceElevated,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body1.copyWith(color: AppColors.text),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: AppColors.surfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class _SimpleAreaChart extends StatelessWidget {
  const _SimpleAreaChart();

  @override
  Widget build(BuildContext context) {
    const values = [28.0, 50.0, 68.0, 86.0, 70.0, 52.0, 38.0];
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (value) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: value,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: .2 + value / 200,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!, style: AppTextStyles.linkText),
          ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: AppColors.surfaceElevated,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmCard extends StatelessWidget {
  const _WarmCard({
    required this.child,
    this.color = AppColors.surfaceElevated,
    this.borderColor,
    this.padding = const EdgeInsets.all(20),
    this.minHeight,
  });

  final Widget child;
  final Color color;
  final Color? borderColor;
  final EdgeInsets padding;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.border.withValues(alpha: .65),
        ),
      ),
      child: child,
    );
  }
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({
    required this.controller,
    required this.child,
    required this.interval,
    this.yOffset = 8,
  });

  final AnimationController controller;
  final Widget child;
  final Interval interval;
  final double yOffset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;

    final animation = CurvedAnimation(parent: controller, curve: interval);
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, yOffset * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height, required this.radius});

  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, this.height = 16});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: .55),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MoodEntry {
  const _MoodEntry(this.emoji, this.title, this.time);

  final String emoji;
  final String title;
  final String time;
}

void _pushPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}
