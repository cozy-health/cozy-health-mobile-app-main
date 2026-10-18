import '../../../../core/widgets/profile_avatar.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../data/profile_repository.dart';
import '../../../../core/services/local_db_service.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});
  Future<DateTime?> _joined() async {
    try {
      final settings = await LocalDbService().settingsBox();
      return DateTime.tryParse('${settings.get('account_created_at') ?? ''}');
    } catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRouter.editProfile),
            child: Text(
              'Edit',
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              StreamBuilder<UserProfile?>(
                stream: ProfileRepository().watchProfile(),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final name = profile?.name ?? 'Loading...';
                  final username = profile?.username != null
                      ? '@${profile!.username}'
                      : '';
                  final bio =
                      profile?.bio ?? '"Trying to be kinder\nto myself."';

                  return Column(
                    children: [
                      // Avatar
                      ProfileAvatar(profile: profile, size: 96),
                      SizedBox(height: 24),

                      Text(
                        name,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      if (username.isNotEmpty) ...[
                        Text(
                          username,
                          style: AppTextStyles.body2.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                        SizedBox(height: 24),
                      ],

                      Text(
                        bio,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body1.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 32),

                      // Stats
                      StreamBuilder<List<MoodEntry>>(
                        stream: MoodRepository().watchMoodEntries(),
                        builder: (context, moodSnapshot) {
                          final moods = moodSnapshot.data ?? [];
                          final entriesCount = moods.length;
                          final streak = moods.isNotEmpty ? 1 : 0; // Simplified

                          return Row(
                            children: [
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 80,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: AppSurface.border(context),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$entriesCount',
                                        style: AppTextStyles.heading2.copyWith(
                                          fontSize: 24,
                                        ),
                                      ),
                                      Text(
                                        'Entries',
                                        style: AppTextStyles.body2.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 80,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: AppSurface.border(context),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$streak',
                                        style: AppTextStyles.heading2.copyWith(
                                          fontSize: 24,
                                        ),
                                      ),
                                      Text(
                                        'Day streak',
                                        style: AppTextStyles.body2.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.textMutedDark
                                              : AppColors.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 32),
                    ],
                  );
                },
              ),

              FutureBuilder<DateTime?>(future: _joined(), builder: (context, snapshot) => Text(
                snapshot.data == null ? 'Your wellness journey' : 'Joined ${DateFormat.yMMMM().format(snapshot.data!.toLocal())}',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              )),
              SizedBox(height: 32),

              // Sections
              Material(
                color: Theme.of(context).colorScheme.surface,
                shape: AppSurface.shape(context, BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.push(AppRouter.moodHistory),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: AppSurface.border(context),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent entries',
                            style: AppTextStyles.body1.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSubtleDark
                              : AppColors.textSubtleLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              Material(
                color: Theme.of(context).colorScheme.surface,
                shape: AppSurface.shape(context, BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: AppSurface.border(context),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Achievements',
                            style: AppTextStyles.body1.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSubtleDark
                              : AppColors.textSubtleLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reuses the profile route and account-scoped settings instead of a second store.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});
  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late final Future<Map<String, DateTime>> _awards = _load();
  final String? _owner = LocalDbService().activeUserId;
  int _longest = 0;
  static const _labels = {
    'first_mood': 'Your first check-in',
    'first_journal': 'Your first journal entry',
    'streak_3': 'Three days of checking in',
    'streak_7': 'A week of checking in',
    'streak_30': 'Thirty days of checking in',
  };
  Future<Map<String, DateTime>> _load() async {
    final local = LocalDbService();
    final settings = await local.settingsBox();
    if (_owner != local.activeUserId || _owner?.startsWith('guest_') != false) {
      return {};
    }
    final stored = settings.get('earned_milestones_v1');
    final awards = <String, DateTime>{};
    if (stored is Map) {
      for (final entry in stored.entries) {
        final date = DateTime.tryParse('${entry.value}');
        if (date != null) awards['${entry.key}'] = date;
      }
    }
    try {
      final response = await ApiClient().get('/wellness/achievements');
      if (_owner != local.activeUserId) return {};
      for (final row in response.data['data'] as List) {
        final date = DateTime.tryParse('${row['earned_date']}');
        if (date != null) awards['${row['milestone']}'] = date;
      }
    } catch (_) {
      // Retain earned offline milestones until this account reconnects.
    }
    if (_owner != local.activeUserId) return {};
    final moods = local.getAllMoodEntries()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final journals = local.getAllJournalEntries()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (moods.isNotEmpty) {
      awards.putIfAbsent('first_mood', () => moods.first.createdAt);
    }
    if (journals.isNotEmpty) {
      awards.putIfAbsent('first_journal', () => journals.first.createdAt);
    }
    final days =
        moods
            .map((entry) {
              final date = local.accountTime(entry.createdAt);
              return DateTime.utc(date.year, date.month, date.day);
            })
            .toSet()
            .toList()
          ..sort();
    DateTime? previous;
    var streak = 0;
    for (final day in days) {
      streak = previous != null && day.difference(previous).inDays == 1
          ? streak + 1
          : 1;
      if (streak > _longest) _longest = streak;
      for (final target in [3, 7, 30]) {
        if (streak >= target) {
          awards.putIfAbsent(
            'streak_$target',
            () => DateTime(day.year, day.month, day.day),
          );
        }
      }
      previous = day;
    }
    await settings.put('earned_milestones_v1', {
      for (final entry in awards.entries)
        entry.key: entry.value.toIso8601String(),
    });
    return awards;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your achievements')),
    body: StreamBuilder<void>(
      stream: LocalDbService().accountChanges,
      builder: (context, _) {
        if (_owner != LocalDbService().activeUserId) {
          return const Center(
            child: Text('Sign in to view your achievements.'),
          );
        }
        return FutureBuilder<Map<String, DateTime>>(
          future: _awards,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Could not load achievements. Please reopen this screen.',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final awards = snapshot.data ?? {};
            final earned =
                awards.entries
                    .where((entry) => _labels.containsKey(entry.key))
                    .toList()
                  ..sort((a, b) => a.value.compareTo(b.value));
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.emoji_events_outlined, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          '${earned.length} of ${_labels.length} milestones earned',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Every small step counts. Earned milestones stay with you when a streak ends.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your milestone timeline',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (earned.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Your first check-in or journal entry starts your timeline.',
                    ),
                  ),
                for (final award in earned)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(_labels[award.key] ?? award.key),
                      subtitle: Text(
                        'Earned ${DateFormat.yMMMd().format(award.value.toLocal())}',
                      ),
                    ),
                  ),
                if (LocalDbService().pendingItems.any(
                  (item) =>
                      item.type == 'mood_entry' || item.type == 'journal_entry',
                ))
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Some activity is saved on this device and waiting to sync.',
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Your next steps',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final entry in _labels.entries.where(
                  (entry) => !awards.containsKey(entry.key),
                ))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value),
                          const SizedBox(height: 8),
                          if (entry.key.startsWith('streak_')) ...[
                            LinearProgressIndicator(
                              value:
                                  (_longest / int.parse(entry.key.substring(7)))
                                      .clamp(0.0, 1.0),
                            ),
                            Text('Best streak: $_longest days'),
                          ] else
                            const Text('Ready whenever you are'),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    ),
  );
}
