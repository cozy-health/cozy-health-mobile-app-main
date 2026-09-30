import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  // Mock data
  final List<String> _blockedUsers = ['toxic_user99', 'spam_bot_2026', 'unwanted_contact'];

  void _unblockUser(String username) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Unblock @$username?',
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'They will be able to see your public profile and interact with you again.',
            style: AppTextStyles.body1.copyWith(color: AppColors.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _blockedUsers.remove(username);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('@$username has been unblocked.')),
                );
              },
              child: Text(
                'Unblock',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Blocked users',
                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'These users cannot see your profile or interact with you.',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 32),
            
            Expanded(
              child: _blockedUsers.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 64, color: AppColors.textSubtle),
            const SizedBox(height: 24),
            Text(
              'No blocked users',
              style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re all caught up.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 64), // Offset slightly visually
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final username = _blockedUsers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    username[0].toUpperCase(),
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '@$username',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _unblockUser(username),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Unblock',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
