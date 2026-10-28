import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/streak_controller.dart';
import '../../../../core/models/streak_progress.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/achievements_repository.dart';
import '../../data/wellness_progress.dart';
import '../widgets/streak_progress_panel.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key, this.load});
  final Future<AchievementSnapshot> Function()? load;
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<AchievementSnapshot> _future = _load();
  final _owner = LocalDbService().activeUserId;
  StreakController? _streak;
  @override
  void initState() {
    super.initState();
    if (_owner != null &&
        !_owner.startsWith('guest_') &&
        !DemoMode.instance.enabled) {
      _streak = StreakController()
        ..addListener(_changed)
        ..start();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _streak?.removeListener(_changed);
    _streak?.dispose();
    super.dispose();
  }

  Future<AchievementSnapshot> _load() =>
      (widget.load ?? AchievementsRepository().load)();
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), w = context.cozyColors.wellness;
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      appBar: AppBar(title: const Text('Your achievements')),
      body: SafeArea(
        child: StreamBuilder<void>(
          stream: LocalDbService().accountChanges,
          builder: (context, _) {
            if (_owner != LocalDbService().activeUserId) {
              return const Center(
                child: Text('Reopen achievements for this account.'),
              );
            }
            return FutureBuilder<AchievementSnapshot>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: WellnessAction(
                      label: 'Retry achievements',
                      onPressed: () => setState(() => _future = _load()),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return AchievementContent(
                  snapshot: snapshot.data!,
                  streak: _streak?.progress,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AchievementContent extends StatelessWidget {
  const AchievementContent({super.key, required this.snapshot, this.streak});
  final AchievementSnapshot snapshot;
  final StreakProgress? streak;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
    final earned = WellnessMilestone.catalog
        .where((m) => snapshot.awards.containsKey(m.id))
        .length;
    final current = streak?.currentDays ?? snapshot.progress.current;
    return ListView(
      padding: EdgeInsets.all(w.page),
      children: [
        Text('Small steps, recognised', style: t.textTheme.headlineSmall),
        SizedBox(height: w.small),
        Text(
          '$earned of ${WellnessMilestone.catalog.length} milestones earned. Your progress belongs to you.',
        ),
        SizedBox(height: w.sectionSpacing),
        StreakProgressPanel(progress: snapshot.progress, streak: streak),
        SizedBox(height: w.sectionSpacing),
        if (snapshot.localOnly || snapshot.remoteUnavailable) ...[
          WellnessPanel(
            child: Text(
              snapshot.localOnly
                  ? 'Progress on this device. Sign in to keep milestones with your account.'
                  : 'Showing saved progress. Account milestones will refresh when you reconnect.',
            ),
          ),
          SizedBox(height: w.gap),
        ],
        for (final milestone in WellnessMilestone.catalog) ...[
          WellnessPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      snapshot.awards.containsKey(milestone.id)
                          ? Icons.verified_outlined
                          : Icons.emoji_events_outlined,
                      color: snapshot.awards.containsKey(milestone.id)
                          ? c.primary
                          : c.onSurfaceVariant,
                    ),
                    SizedBox(width: w.contentGap),
                    Expanded(
                      child: Text(
                        milestone.title,
                        style: t.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: w.contentGap),
                Text(milestone.description),
                SizedBox(height: w.small),
                if (snapshot.awards[milestone.id] case final DateTime date)
                  Text(
                    'Earned ${DateFormat.yMMMd().format(date)}',
                    style: t.textTheme.labelLarge?.copyWith(
                      color: wellnessAccentInk(context),
                    ),
                  )
                else ...[
                  const Text('Not earned yet'),
                  if (milestone.streakTarget case final int target) ...[
                    SizedBox(height: w.small),
                    LinearProgressIndicator(
                      value: (current / target).clamp(0, 1),
                      semanticsLabel:
                          'Current streak: $current of $target check-in days towards ${milestone.title}',
                    ),
                    SizedBox(height: w.small),
                    Text(
                      '$current of $target check-in days in your current streak',
                    ),
                  ],
                ],
              ],
            ),
          ),
          SizedBox(height: w.contentGap),
        ],
      ],
    );
  }
}
