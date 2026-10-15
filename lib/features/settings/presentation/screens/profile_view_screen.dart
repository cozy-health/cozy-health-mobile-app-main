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

class ProfileViewScreen extends StatelessWidget {
  const ProfileViewScreen({super.key});

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

              Text(
                'Joined March 2026',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 32),

              // Sections
              Material(
                color: Theme.of(context).colorScheme.surface,
                shape: AppSurface.shape(context, BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {},
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
                  onTap: () {},
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
