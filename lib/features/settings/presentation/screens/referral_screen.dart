import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

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
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Invite a friend',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'If Cozy Health has helped you, share it with someone who might need it.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 32),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: AppSurface.border(context),
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.qr_code_2,
                      size: 160,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48),
              Text(
                'Your invite link',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: AppSurface.border(context),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'cozy.health/r/sarahchen',
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Copy link',
                      onPressed: () {
                        AppSnackbar.show(
                          context,
                          AppSnackbar.fromLegacy(content: Text('Link copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () {
                  // native share
                  AppSnackbar.show(
                    context,
                    AppSnackbar.fromLegacy(
                      content: Text('Opening share sheet...'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppSurface.tint(
                      context,
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: AppSurface.border(context),
                  ),
                  child: Center(
                    child: Text(
                      'Share link',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48),
              Text(
                'Friends who joined',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              _buildFriendsList(context),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList(BuildContext context) {
    final friends = ['alex', 'maya', 'jordan'];

    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                'No one yet.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'That\'s okay.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: AppSurface.border(context),
      ),
      child: Column(
        children: friends.map((friend) {
          final isLast = friend == friends.last;
          return Column(
            children: [
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        friend[0].toUpperCase(),
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '@$friend',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 48, right: 16),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
