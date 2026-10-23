import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/profile_repository.dart';
import '../../data/wellness_progress.dart';
import '../widgets/streak_progress_panel.dart';
import 'achievements_screen.dart';
export 'achievements_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({super.key, this.profileStream, this.moodStream});
  final Stream<UserProfile?>? profileStream;
  final Stream<List<MoodEntry>>? moodStream;
  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  late final _profile =
      widget.profileStream ?? ProfileRepository().watchProfile();
  late final _moods = widget.moodStream ?? MoodRepository().watchMoodEntries();
  final _owner = LocalDbService().activeUserId;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context), w = context.cozyColors.wellness;
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      appBar: AppBar(title: const Text('Your profile')),
      body: SafeArea(
        child: StreamBuilder<void>(
          stream: LocalDbService().accountChanges,
          builder: (context, _) {
            if (_owner != LocalDbService().activeUserId) {
              return const Center(
                child: Text('Reopen your profile for this account.'),
              );
            }
            return StreamBuilder<UserProfile?>(
              stream: _profile,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Your profile could not be loaded. Reopen to try again.',
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final p = snapshot.data;
                return ListView(
                  padding: EdgeInsets.all(w.page),
                  children: [
                    WellnessPanel(
                      tinted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(profile: p, size: 80),
                          SizedBox(height: w.gap),
                          Text(
                            p?.name ?? 'Your profile',
                            style: t.textTheme.headlineSmall,
                          ),
                          if (p != null &&
                              p.showUsername &&
                              (p.username?.trim().isNotEmpty ?? false)) ...[
                            SizedBox(height: w.tight),
                            Text(
                              '@${p.username}',
                              style: t.textTheme.bodyMedium?.copyWith(
                                color: t.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (p?.bio?.trim().isNotEmpty ?? false) ...[
                            SizedBox(height: w.contentGap),
                            Text(p!.bio!),
                          ],
                          SizedBox(height: w.gap),
                          WellnessAction(
                            label: 'Edit profile',
                            icon: Icons.edit_outlined,
                            filled: true,
                            onPressed: () =>
                                context.push(AppRouter.editProfile),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w.sectionSpacing),
                    Text('Your space', style: t.textTheme.titleLarge),
                    SizedBox(height: w.small),
                    const Text(
                      'Your check-ins, streak and achievements here are private.',
                    ),
                    SizedBox(height: w.contentGap),
                    if (p?.showStats ?? true)
                      StreamBuilder<List<MoodEntry>>(
                        stream: _moods,
                        builder: (context, moods) {
                          if (moods.hasError) {
                            return const WellnessPanel(
                              child: Text(
                                'Check-in progress could not be loaded.',
                              ),
                            );
                          }
                          if (!moods.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final progress = WellnessProgress(
                            moods: moods.data!,
                            journals: const [],
                            now: DateTime.now(),
                            calendarTime: LocalDbService().accountTime,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WellnessPanel(
                                child: Text(
                                  '${progress.entryCount} saved check-ins',
                                  style: t.textTheme.titleMedium,
                                ),
                              ),
                              SizedBox(height: w.contentGap),
                              StreakProgressPanel(progress: progress),
                              SizedBox(height: w.sectionSpacing),
                            ],
                          );
                        },
                      ),
                    _link(
                      context,
                      Icons.history_rounded,
                      'Recent entries',
                      'Return to your mood log',
                      () => context.push(AppRouter.moodHistory),
                    ),
                    _link(
                      context,
                      Icons.emoji_events_outlined,
                      'Achievements',
                      'See your earned milestones',
                      () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AchievementsScreen(),
                        ),
                      ),
                    ),
                    _link(
                      context,
                      Icons.bookmark_border_rounded,
                      'Saved articles',
                      'Keep helpful reads close',
                      () => context.push(AppRouter.savedArticles),
                    ),
                    if (p != null &&
                        _owner != null &&
                        !_owner.startsWith('guest_')) ...[
                      SizedBox(height: w.gap),
                      Text(
                        'Your community identity',
                        style: t.textTheme.titleLarge,
                      ),
                      SizedBox(height: w.small),
                      const Text(
                        'Your public profile shows public posts. It does not share your check-ins or journal.',
                      ),
                      SizedBox(height: w.contentGap),
                      _link(
                        context,
                        Icons.person_outline_rounded,
                        'Preview public profile',
                        'See what other members can view',
                        () => context.push(
                          AppRouter.userProfile,
                          extra: {
                            'authorId': _owner,
                            'username': p.showUsername && p.username != null
                                ? p.username
                                : p.name,
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _link(
    BuildContext context,
    IconData icon,
    String label,
    String subtitle,
    VoidCallback action,
  ) {
    final w = context.cozyColors.wellness, t = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: w.contentGap),
      child: AppPressable(
        onPressed: action,
        child: WellnessPanel(
          child: Row(
            children: [
              Icon(icon),
              SizedBox(width: w.contentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: t.textTheme.titleMedium),
                    SizedBox(height: w.tight),
                    Text(subtitle, style: t.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
