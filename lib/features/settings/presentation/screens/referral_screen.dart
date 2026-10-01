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
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
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
                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                'If Cozy Health has helped you, share it with someone who might need it.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2, size: 160, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Your invite link',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'cozy.health/r/sarahchen',
                        style: AppTextStyles.body1.copyWith(color: AppColors.text),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.textSubtle),
                      tooltip: 'Copy link',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  // native share
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening share sheet...')),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'Share link',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Friends who joined',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              _buildFriendsList(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    final friends = ['alex', 'maya', 'jordan'];
    
    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                'No one yet.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              ),
              Text(
                'That\'s okay.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
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
                        style: AppTextStyles.body2.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '@$friend',
                      style: AppTextStyles.body1.copyWith(color: AppColors.text),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 48, right: 16),
                  child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
