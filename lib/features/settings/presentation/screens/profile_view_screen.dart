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
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRouter.editProfile),
            child: Text(
              'Edit',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
            StreamBuilder<UserProfile?>(
              stream: ProfileRepository().watchProfile(),
              builder: (context, profileSnapshot) {
                final profile = profileSnapshot.data;
                final name = profile?.name ?? 'Loading...';
                final username = profile?.username != null ? '@${profile!.username}' : '';
                final bio = profile?.bio ?? '"Trying to be kinder\nto myself."';
                final avatarUrl = profile?.avatarUrl;
                
                return Column(
                  children: [
                    // Avatar
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.midGrey,
                        image: avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: avatarUrl == null
                          ? const Icon(Icons.person, color: AppColors.white, size: 48)
                          : null,
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      name,
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (username.isNotEmpty) ...[
                      Text(
                        username,
                        style: AppTextStyles.body2.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body1.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
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
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 1),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$entriesCount',
                                      style: AppTextStyles.heading2.copyWith(fontSize: 24),
                                    ),
                                    Text(
                                      'Entries',
                                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border, width: 1),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$streak',
                                      style: AppTextStyles.heading2.copyWith(fontSize: 24),
                                    ),
                                    Text(
                                      'Day streak',
                                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }
            ),
            
            Text(
              'Joined March 2026',
              style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
              
              // Sections
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent entries',
                            style: AppTextStyles.body1.copyWith(color: AppColors.text),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Achievements',
                            style: AppTextStyles.body1.copyWith(color: AppColors.text),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.textSubtle),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
