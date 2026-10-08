import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/repositories/home_repository.dart';
import '../../../../core/api/auth_token_service.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/guest_session_service.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/user_data_fetcher.dart';
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
  final HomeRepository _homeRepo = HomeRepository();
  late final Stream<List<MoodEntry>> _moodStream;
  DashboardData? _dashboard;
  bool _loadingDashboard = true;
  bool _dashboardFailed = false;

  final List<String> _affirmations = const [
    "You're doing great.\nSmall steps count.",
    "It's okay to rest.",
    "Feelings are visitors.\nLet them come and go.",
  ];

  @override
  void initState() {
    super.initState();
    _moodStream = _moodRepo.watchMoodEntries();
    _loadDashboard();
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

  Future<void> _loadDashboard() async {
    final cached = await _homeRepo.getCachedDashboard();
    final offline =
        cached ?? await _homeRepo.getCachedDashboard(allowStale: true);
    if (!mounted) return;
    if (offline != null) setState(() => _dashboard = offline);
    if (!await AuthTokenService.hasToken()) {
      if (mounted) setState(() => _loadingDashboard = false);
      return;
    }
    try {
      final fresh = await _homeRepo.fetchDashboard();
      if (mounted) {
        setState(() {
          _dashboard = fresh;
          _dashboardFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dashboardFailed = true);
        if (_dashboard == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not refresh Home. Your saved moods are still available.',
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  int _localStreak(List<MoodEntry> entries) {
    final dates = entries.map((entry) {
      final day = entry.createdAt.toLocal();
      return DateTime(day.year, day.month, day.day);
    }).toSet();
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    if (!dates.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
    var streak = 0;
    while (dates.contains(day)) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == HomeDashboardState.error) {
      return _HomeErrorView(onRetry: () {});
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MoodEntry>>(
          stream: _moodStream,
          builder: (context, snapshot) {
            if ((_loadingDashboard && _dashboard == null) ||
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
              return const _HomeSkeleton();
            }

            final entries = snapshot.data ?? [];
            final isEmpty = _dashboard == null
                ? entries.isEmpty
                : _dashboard!.recentEntries.isEmpty &&
                      _dashboard!.todayMood == null;
            final allMoods = LocalDbService.instance.getAllMoodEntries();
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            final moodsThisWeek = allMoods.where((entry) {
              return entry.createdAt.toLocal().isAfter(weekAgo);
            }).toList();
            debugPrint(
              'Home thisWeek: total=${allMoods.length} thisWeek=${moodsThisWeek.length}',
            );

            // Determine state dynamically
            final dynamicState = isEmpty
                ? HomeDashboardState.firstTime
                : HomeDashboardState.returningUser;

            // Compute streak
            final now = DateTime.now();
            final streak = _dashboard?.streakDays ?? _localStreak(entries);

            // Recent 2 entries
            final recentEntries =
                _dashboard?.recentEntries.take(2).map((row) {
                  final local = entries
                      .where((entry) => entry.id == row['id'])
                      .firstOrNull;
                  return local ??
                      MoodEntry.fromJson({
                        ...row,
                        'client_created_at':
                            row['client_created_at'] ?? row['created_at'],
                        'client_updated_at':
                            row['client_created_at'] ?? row['created_at'],
                      });
                }).toList() ??
                entries.take(2).toList();
            final hasMoodToday = _dashboard != null
                ? _dashboard!.todayMood != null
                : entries.isNotEmpty &&
                      entries.first.createdAt.day == now.day &&
                      entries.first.createdAt.month == now.month &&
                      entries.first.createdAt.year == now.year;

            return _DashboardScope(
              data: _dashboard,
              child: Semantics(
                label:
                    'Home dashboard loaded. $streak day streak. ${recentEntries.length} recent entries.',
                child: RefreshIndicator(
                  onRefresh: () async {
                    await UserDataFetcher().fetchAll();
                    await _loadDashboard();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      16,
                      24,
                      AppScaffoldPadding.tabScrollBottom(context).bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_dashboardFailed) ...[
                          _OfflineBanner(onRetry: _loadDashboard),
                          const SizedBox(height: 16),
                        ],
                        const _GuestBanner(),
                        _AnimatedIn(
                          controller: _entranceController,
                          interval: const Interval(
                            0,
                            .35,
                            curve: Curves.easeOutCubic,
                          ),
                          child: const _Header(),
                        ),
                        InkWell(
                          onTap: () => context.push(AppRouter.crisisHub),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Need help now?',
                              style: AppTextStyles.body2.copyWith(
                                fontSize: 13,
                                color: AppColors.crisisPrimary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
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
                            child: _MoodChart(entries: moodsThisWeek),
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
                              subtitle:
                                  'Notes stay private and easy to revisit.',
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardScope extends InheritedWidget {
  const _DashboardScope({required this.data, required super.child});
  final DashboardData? data;
  static DashboardData? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DashboardScope>()?.data;
  @override
  bool updateShouldNotify(_DashboardScope oldWidget) => data != oldWidget.data;
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: GuestSessionService().isGuestSession(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "You're browsing as a guest",
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRouter.createAccount),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        );
      },
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$name.',
                    style: AppTextStyles.heading1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => context.push(AppRouter.notifications),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
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
          borderColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: borderOpacity),
          minHeight: 140,
          child: child!,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hasMoodToday
                ? 'You logged: ${_DashboardScope.of(context)?.todayMood?['mood'] ?? 'a mood'}.\nWant to add a note?'
                : 'How are you feeling\nright now?',
            style: AppTextStyles.heading1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
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
      borderColor: Theme.of(context).colorScheme.primary.withValues(alpha: .15),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceElevatedLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.self_improvement,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .78),
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Welcome to Cozy Health.',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Let's start with how\nyou're feeling today.",
            textAlign: TextAlign.center,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
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
                backgroundColor: Theme.of(context).colorScheme.primary,
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
    final weekly = _DashboardScope.of(context)?.weeklyMoods ?? [];
    final count = weekly.fold<int>(
      0,
      (sum, row) => sum + (row['count'] as num).toInt(),
    );
    final total = weekly.fold<double>(
      0,
      (sum, row) =>
          sum +
          (row['avg_intensity'] as num).toDouble() * (row['count'] as num),
    );
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
            icon: MoodEntry.moodEmojis['good'] ?? '',
            title: count == 0
                ? 'No moods\nthis week'
                : (total / count).toStringAsFixed(1),
            subtitle: count == 0 ? '' : 'Avg intensity',
            isEmpty: isEmpty,
            onTap: isEmpty
                ? () => context.push(AppRouter.moodFeeling)
                : () => context.push(AppRouter.insights),
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
            color: Theme.of(context).colorScheme.surface,
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
                  color: isEmpty
                      ? Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
  const _MoodChart({required this.entries});

  final List<MoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final weekly = _DashboardScope.of(context)?.weeklyMoods;
    final count =
        weekly?.fold<int>(
          0,
          (sum, row) => sum + (row['count'] as num).toInt(),
        ) ??
        entries.length;
    if (count < 3) {
      return const _EmptyCard(
        icon: Icons.show_chart,
        title: 'Log 3 moods to see trends',
        subtitle: 'Keep logging. Your patterns will appear here gently.',
      );
    }

    final values = weekly == null
        ? _weeklyValues(entries)
        : List<double>.generate(7, (index) {
            final rows = weekly.where(
              (row) =>
                  DateTime.parse(row['day'] as String).weekday == index + 1,
            );
            return rows.isEmpty
                ? 0
                : ((rows.first['avg_intensity'] as num).toDouble() * 7)
                      .clamp(0, 70)
                      .toDouble();
          });
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GestureDetector(
      onTap: () => context.push(AppRouter.insights),
      child: _WarmCard(
        color: AppColors.surfaceElevated,
        minHeight: 120,
        child: Semantics(
          label: 'Weekly average mood intensity chart.',
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .78),
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
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

  List<double> _weeklyValues(List<MoodEntry> entries) {
    final values = List<double>.filled(7, 0);
    for (final entry in entries) {
      final local = entry.createdAt.toLocal();
      values[local.weekday - 1] = (entry.intensity.clamp(1, 10) * 10)
          .toDouble();
    }
    return values.map((value) => value == 0 ? 12.0 : value).toList();
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final MoodEntry entry;

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
              Text(entry.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mood,
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(entry.createdAt),
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
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
                      color: Theme.of(context).colorScheme.onSurface,
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
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline. Showing your last data.",
              style: AppTextStyles.body2.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Re-check connection',
            onPressed: onRetry,
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
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
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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

class StreakDetailScreen extends StatelessWidget {
  const StreakDetailScreen({super.key});

  String _milestone(BuildContext context, int goal) {
    final streak = _DashboardScope.of(context)?.streakDays ?? 0;
    return streak >= goal ? 'Achieved!' : '${goal - streak} to go';
  }

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
                  '${_DashboardScope.of(context)?.streakDays ?? 0}',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 48,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'day streak',
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "You've logged your\nmood ${_DashboardScope.of(context)?.streakDays ?? 0} days in a row.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
                  index < (_DashboardScope.of(context)?.streakDays ?? 0)
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 16,
                  color: index < (_DashboardScope.of(context)?.streakDays ?? 0)
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.borderStrong,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Milestones',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _MilestoneCard(text: '7-day streak', value: _milestone(context, 7)),
          const SizedBox(height: 8),
          _MilestoneCard(text: '30-day streak', value: _milestone(context, 30)),
          const SizedBox(height: 8),
          _MilestoneCard(
            text: '100-day streak',
            value: _milestone(context, 100),
          ),
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
                    color: Theme.of(context).colorScheme.onSurface,
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
            children: [
              Expanded(
                child: _BreakdownCard(
                  title: 'Most common',
                  value: "${MoodEntry.moodEmojis['good']} Good",
                ),
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
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Breathing (4 times)\n• Journaling (2 times)',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Gentle note',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You logged 12 entries this week. That's a lot of self-awareness.",
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
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
                    icon: Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.heading2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
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
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
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
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .2 + value / 200),
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
              color: Theme.of(context).colorScheme.onSurface,
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
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = isDark && color == AppColors.surfaceElevated
        ? AppColors.surfaceElevatedDark
        : color;
    final effectiveBorder =
        borderColor ??
        (isDark
            ? AppColors.borderDark.withValues(alpha: .9)
            : AppColors.border.withValues(alpha: .65));

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: effectiveBorder),
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

void _pushPage(BuildContext context, Widget page) {
  final dashboard = _DashboardScope.of(context);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _DashboardScope(data: dashboard, child: page),
    ),
  );
}
