import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/mood_artwork.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import '../../../../core/data/demo_mode.dart';
import '../widgets/mood_chips_row.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/sync_queue_badge.dart';
import '../../../../core/widgets/background_restore_badge.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';

import '../widgets/feature_tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/home_quiz_card.dart';
import '../widgets/cozy_calendar.dart';
import '../widgets/journaling_card.dart';
import '../widgets/preference_suggestions.dart';
import '../../../../core/widgets/affirmation_panel.dart';
import '../../../../core/services/affirmation_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/repositories/home_repository.dart';
import '../../../../core/api/auth_token_service.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/guest_session_service.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/user_data_fetcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../features/settings/data/profile_repository.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../features/notifications/data/notification_repository.dart';

enum HomeDashboardState {
  returningUser,
  firstTime,
  partialData,
  loading,
  offline,
  error,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.state = HomeDashboardState.returningUser,
    this.tourTargets,
    this.notificationFocus,
    this.affirmationController,
  });
  final FeatureTourTargets? tourTargets;
  final String? notificationFocus;
  final AffirmationController? affirmationController;

  final HomeDashboardState state;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  final _reminderTarget = GlobalKey();
  bool _reminderFocused = false;

  void _focusReminder() {
    if (_reminderFocused || widget.notificationFocus == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _reminderTarget.currentContext;
      if (!mounted || target == null) return;
      _reminderFocused = true;
      Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: Duration.zero,
      );
    });
  }

  final MoodRepository _moodRepo = MoodRepository();
  final HomeRepository _homeRepo = HomeRepository();
  late final Stream<List<MoodEntry>> _moodStream;
  DashboardData? _dashboard;
  bool _loadingDashboard = true;
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
    if (DemoMode.instance.enabled) {
      if (mounted) {
        setState(() {
          _dashboard = null;
          _loadingDashboard = false;
        });
      }
      return;
    }
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
        });
      }
    } catch (_) {
      if (mounted) {
        if (_dashboard == null) {
          AppSnackbar.show(
            context,
            AppSnackbar.fromLegacy(
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
    _focusReminder();
    if (widget.state == HomeDashboardState.error) {
      return _HomeErrorView(onRetry: () {});
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MoodEntry>>(
          stream: _moodStream,
          initialData: _moodRepo.currentEntries(),
          builder: (context, snapshot) {
            if ((_loadingDashboard &&
                    _dashboard == null &&
                    (snapshot.data?.isEmpty ?? true)) ||
                snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
              return const _HomeSkeleton();
            }

            final entries = snapshot.data ?? [];
            final isEmpty = _dashboard == null
                ? entries.isEmpty
                : _dashboard!.recentEntries.isEmpty &&
                      _dashboard!.todayMood == null;
            final allMoods = entries;
            final weekAgo = DateTime.now().subtract(const Duration(days: 7));
            final moodsThisWeek = allMoods.where((entry) {
              return entry.createdAt.toLocal().isAfter(weekAgo);
            }).toList();

            // Compute streak
            final now = DateTime.now();
            final streak = _dashboard?.streakDays ?? _localStreak(entries);

            // Up to three recent entries
            final recentEntries =
                _dashboard?.recentEntries.take(3).map((row) {
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
                entries.take(3).toList();
            final hasMoodToday = _dashboard != null
                ? _dashboard!.todayMood != null
                : entries.isNotEmpty &&
                      entries.first.createdAt.day == now.day &&
                      entries.first.createdAt.month == now.month &&
                      entries.first.createdAt.year == now.year;

            return FeatureTour(
              targets: widget.tourTargets,
              child: _DashboardScope(
                data: _dashboard,
                child: Semantics(
                  label:
                      'Home dashboard loaded. $streak day streak. ${recentEntries.length} recent entries.',
                  child: RefreshIndicator(
                    onRefresh: () async {
                      if (!DemoMode.instance.enabled) {
                        await UserDataFetcher().fetchAll();
                      }
                      await _loadDashboard();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _GuestBanner(),
                          const SyncQueueBadge(),
                          const BackgroundRestoreBadge(),
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
                            onTap: () => context.push(AppRouter.crisisContact),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Need help now?',
                                style: AppTextStyles.body2.copyWith(
                                  fontSize: 13,
                                  color: context.cozyColors.crisis,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          _HomeEmotionStrip(key: widget.tourTargets?.hero),
                          SizedBox(height: 16),
                          const PreferenceSuggestions(),
                          _HomeDesignCards(
                            reminderKey: _reminderTarget,
                            notificationFocus: widget.notificationFocus,
                            entries: entries,
                            recentEntries: recentEntries,
                            moodsThisWeek: moodsThisWeek,
                            streak: streak,
                            isEmpty: isEmpty,
                            hasMoodToday: hasMoodToday,
                            affirmation: AffirmationPanel(
                              compact: true,
                              controller: widget.affirmationController,
                            ),
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
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
              color: AppSurface.tint(
                context,
                Theme.of(context).colorScheme.primary.withValues(alpha: .08),
              ),
              borderRadius: BorderRadius.circular(12),
              border: AppSurface.border(context),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 10),
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
                  child: Text('Create Account'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeEmotionStrip extends StatelessWidget {
  const _HomeEmotionStrip({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tell cozy how you are feeling today?',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      SizedBox(height: 16),
      const MoodChipsRow(),
    ],
  );
}

class _HomeDesignCards extends StatelessWidget {
  const _HomeDesignCards({
    this.reminderKey,
    this.notificationFocus,
    required this.entries,
    required this.recentEntries,
    required this.moodsThisWeek,
    required this.streak,
    required this.isEmpty,
    required this.hasMoodToday,
    required this.affirmation,
  });
  final List<MoodEntry> entries;
  final List<MoodEntry> recentEntries;
  final List<MoodEntry> moodsThisWeek;
  final int streak;
  final bool isEmpty;
  final bool hasMoodToday;
  final Widget affirmation;
  final GlobalKey? reminderKey;
  final String? notificationFocus;

  @override
  Widget build(BuildContext context) {
    final weekly = _DashboardScope.of(context)?.weeklyMoods;
    final count =
        weekly?.fold<int>(
          0,
          (sum, row) => sum + (row['count'] as num).toInt(),
        ) ??
        moodsThisWeek.length;
    final total =
        weekly?.fold<double>(
          0,
          (sum, row) =>
              sum +
              (row['avg_intensity'] as num).toDouble() * (row['count'] as num),
        ) ??
        moodsThisWeek.fold<double>(0, (sum, entry) => sum + entry.intensity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: notificationFocus == 'affirmation' ? reminderKey : null,
          child: affirmation,
        ),
        const SizedBox(height: 16),
        const HomeQuizCard(),
        SizedBox(height: 16),
        CozyCalendar(
          key: notificationFocus == 'streak' ? reminderKey : null,
          entries: entries,
          recentEntries: recentEntries,
          streak: streak,
          weeklyCount: count,
          weeklyIntensityTotal: total,
          hasMoodToday: hasMoodToday,
          onStreak: isEmpty
              ? () => context.push(AppRouter.moodFeeling)
              : () => _pushPage(context, StreakDetailScreen(streak: streak)),
        ),
        SizedBox(height: 16),
        const JournalingCard(),
      ],
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
            ? ''
            : profileName;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: 'Open profile',
              child: GestureDetector(
                onTap: () => context.push(AppRouter.editProfile),
                child: ProfileAvatar(profile: profile, size: 40),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  if (name.isNotEmpty) SizedBox(height: 4),
                  if (name.isNotEmpty)
                    Text(
                      name.split(RegExp(r'\s+')).first,
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

                  return IconButton(
                    onPressed: () => context.push(AppRouter.notifications),
                    icon: SizedBox(
                      width: 30,
                      height: 30,
                      child: Stack(
                        children: [
                          SvgPicture.asset(
                            'assets/svg/home_notification_bell.svg',
                            width: 30,
                            height: 30,
                            excludeFromSemantics: true,
                          ),
                          if (unreadCount > 0)
                            const Positioned(
                              left: 16,
                              top: 4,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(width: 8, height: 8),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
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
          SizedBox(height: 8),
          Row(
            children: const [
              _SkeletonLine(width: 110, height: 24),
              Spacer(),
              _SkeletonCircle(size: 40),
            ],
          ),
          SizedBox(height: 28),
          const _SkeletonBox(height: 140, radius: 20),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonBox(height: 96, radius: 16)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBox(height: 96, radius: 16)),
            ],
          ),
          SizedBox(height: 32),
          const _SkeletonLine(width: 100),
          SizedBox(height: 12),
          const _SkeletonBox(height: 120, radius: 16),
          SizedBox(height: 32),
          const _SkeletonLine(width: 130),
          SizedBox(height: 12),
          const _SkeletonBox(height: 72, radius: 16),
          SizedBox(height: 8),
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
                    border: AppSurface.border(context),
                    color: Theme.of(context).colorScheme.surfaceContainer,
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
                SizedBox(height: 28),
                Text(
                  "We couldn't load\nyour home screen.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
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
                SizedBox(height: 28),
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
                    child: Text('Try again'),
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
  const StreakDetailScreen({super.key, required this.streak});
  final int streak;

  String _milestone(BuildContext context, int goal) {
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
                SizedBox(height: 18),
                Text(
                  '$streak',
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
                SizedBox(height: 18),
                Text(
                  "You've logged your\nmood $streak days in a row.",
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
          SizedBox(height: 32),
          _WarmCard(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                30,
                (index) => Icon(
                  index < (streak) ? Icons.circle : Icons.circle_outlined,
                  size: 16,
                  color: index < (streak)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
          SizedBox(height: 28),
          Text(
            'Milestones',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          _MilestoneCard(text: '7-day streak', value: _milestone(context, 7)),
          SizedBox(height: 8),
          _MilestoneCard(text: '30-day streak', value: _milestone(context, 30)),
          SizedBox(height: 8),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 10),
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
          SizedBox(height: 28),
          _WarmCard(
            color: Theme.of(context).colorScheme.surfaceContainer,
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
                SizedBox(height: 18),
                const _SimpleAreaChart(),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BreakdownCard(
                  title: 'Most common',
                  value: 'Good',
                  mood: 'good',
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
          SizedBox(height: 28),
          Text(
            'What helped',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '• Breathing (4 times)\n• Journaling (2 times)',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
              height: 1.5,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Gentle note',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8),
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
              SizedBox(height: 24),
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
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('🏆', style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
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
  const _BreakdownCard({required this.title, required this.value, this.mood});

  final String title;
  final String value;
  final String? mood;

  @override
  Widget build(BuildContext context) {
    return _WarmCard(
      color: Theme.of(context).colorScheme.surfaceContainer,
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
          SizedBox(height: 10),
          Row(
            children: [
              if (mood != null && MoodArtwork.assetFor(mood!) != null) ...[
                MoodArtwork(mood: mood!, size: 24),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  value,
                  style: AppTextStyles.heading2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
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

class _WarmCard extends StatelessWidget {
  const _WarmCard({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.surfaceContainer;
    final effectiveBorder = (isDark
        ? AppColors.borderDark.withValues(alpha: .9)
        : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .65));

    return Container(
      width: double.infinity,

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
  });

  final AnimationController controller;
  final Widget child;
  final Interval interval;

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
            offset: Offset(0, 8 * (1 - animation.value)),
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
    return SkeletonLoader(height: height, radius: radius);
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, this.height = 16});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(width: width, height: height, radius: 20);
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(width: size, height: size, radius: size / 2);
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
