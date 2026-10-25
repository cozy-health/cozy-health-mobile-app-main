import '../../../../core/widgets/wellness_panel.dart';
import '../../../settings/data/wellness_progress.dart';
import '../../../settings/presentation/screens/achievements_screen.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/mood_artwork.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import '../../../../core/data/demo_mode.dart';
import '../widgets/mood_chips_row.dart';
import '../widgets/home_design_widgets.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/theme/wellness_tokens.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/widgets/sync_queue_badge.dart';
import '../../../../core/widgets/background_restore_badge.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';

import '../widgets/feature_tour.dart';
import 'package:flutter/material.dart';

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
import '../../../../features/notifications/presentation/widgets/notification_bell.dart';

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
      duration: const WellnessTokens().transition,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!shouldReduceMotion(context)) {
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

  int _localStreak(List<MoodEntry> entries) => WellnessProgress(
    moods: entries,
    journals: const [],
    now: DateTime.now(),
    calendarTime: LocalDbService().accountTime,
  ).current;

  @override
  Widget build(BuildContext context) {
    _focusReminder();
    if (widget.state == HomeDashboardState.error) {
      return _HomeErrorView(onRetry: () {});
    }

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Theme.of(context).colorScheme.onSurface,
          displayColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      child: Scaffold(
        backgroundColor: context.cozyColors.wellness.canvas(
          Theme.of(context).brightness,
          MediaQuery.highContrastOf(context),
        ),
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
                        padding: EdgeInsets.fromLTRB(
                          context.cozyColors.wellness.page,
                          context.cozyColors.wellness.page,
                          context.cozyColors.wellness.page,
                          wellnessFloatingClearance(context),
                        ),
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
                            SizedBox(height: context.cozyColors.wellness.gap),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AppPressable(
                                label: 'Need help now?',
                                onPressed: () =>
                                    context.push(AppRouter.crisisContact),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.cozyColors.wellness.gap,
                                    vertical: context.cozyColors.wellness.small,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      context.cozyColors.wellness.tileRadius,
                                    ),
                                    border: Border.all(
                                      color: context.cozyColors.crisis,
                                      width: MediaQuery.highContrastOf(context)
                                          ? 2
                                          : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite_border,
                                        color: context.cozyColors.crisis,
                                      ),
                                      SizedBox(
                                        width:
                                            context.cozyColors.wellness.small,
                                      ),
                                      Text(
                                        'Need help now?',
                                        style: TextStyle(
                                          color: context.cozyColors.recording
                                              .controlColor(
                                                context.cozyColors.crisis,
                                                Theme.of(
                                                  context,
                                                ).scaffoldBackgroundColor,
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: context.cozyColors.wellness.gap),
                            _HomeEmotionStrip(key: widget.tourTargets?.hero),
                            SizedBox(height: context.cozyColors.wellness.gap),
                            _HomeDesignCards(
                              reminderKey: _reminderTarget,
                              notificationFocus: widget.notificationFocus,
                              entries: entries,
                              streak: streak,
                              isEmpty: isEmpty,
                              hasMoodToday: hasMoodToday,
                              affirmation: AffirmationPanel(
                                compact: true,
                                controller: widget.affirmationController,
                              ),
                            ),
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
  Widget build(BuildContext context) {
    final t = context.cozyColors.wellness;
    return HomeDesignCard(
      color: t.accentPanel(Theme.of(context).colorScheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A MOMENT TO CHECK IN',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          SizedBox(height: t.contentGap),
          Text(
            'How are you feeling today?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: t.heading,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: t.small),
          const Text('Every feeling has a place here.'),
          SizedBox(height: t.gap),
          const MoodChipsRow(),
          SizedBox(height: t.gap),
          const Text('One small check-in. A little more clarity.'),
        ],
      ),
    );
  }
}

class _HomeDesignCards extends StatelessWidget {
  const _HomeDesignCards({
    this.reminderKey,
    this.notificationFocus,
    required this.entries,
    required this.streak,
    required this.isEmpty,
    required this.hasMoodToday,
    required this.affirmation,
  });
  final List<MoodEntry> entries;
  final int streak;
  final bool isEmpty, hasMoodToday;
  final Widget affirmation;
  final GlobalKey? reminderKey;
  final String? notificationFocus;
  @override
  Widget build(BuildContext context) {
    final t = context.cozyColors.wellness;
    Widget title(String label) => Padding(
      padding: EdgeInsets.only(bottom: t.small),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KeyedSubtree(
          key: notificationFocus == 'affirmation' ? reminderKey : null,
          child: affirmation,
        ),
        SizedBox(height: t.sectionSpacing),
        title('Your check-in rhythm'),
        HomeRhythmCard(
          key: notificationFocus == 'streak' ? reminderKey : null,
          entries: entries,
          streak: streak,
          hasMoodToday: hasMoodToday,
          onStreak: isEmpty
              ? () => context.push(AppRouter.moodFeeling)
              : () => _pushPage(context, StreakDetailScreen(streak: streak)),
        ),
        SizedBox(height: t.sectionSpacing),
        const PreferenceSuggestions(),
        SizedBox(height: t.sectionSpacing),
        title('A little more you-time'),
        const HomeFeatureCards(),
        SizedBox(height: t.gap),
        Text(
          'Small steps. Your pace. Your cozy space.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
            AppPressable(
              label: 'Open profile',
              onPressed: () => context.push(AppRouter.editProfile),
              child: Center(child: ProfileAvatar(profile: profile, size: 40)),
            ),
            SizedBox(width: context.cozyColors.wellness.small),
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
                      name,
                      style: AppTextStyles.heading2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const NotificationBell(),
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
  @override
  Widget build(BuildContext context) => const AchievementsScreen();
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
  const _WarmCard({required this.child, this.color});

  final Widget child;
  final Color? color;

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

      padding: const EdgeInsets.all(20),
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
    if (shouldReduceMotion(context)) return child;

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
