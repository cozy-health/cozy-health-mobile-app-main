import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              StreamBuilder<UserProfile?>(
                stream: ProfileRepository().watchProfile(),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final name = profile?.name ?? 'Loading...';
                  final email = profile?.email ?? 'Loading...';
                  final avatarUrl = profile?.avatarUrl;

                  return Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () {
                        context.push(AppRouter.profileView);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 88,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
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
                                  ? const Icon(Icons.person, color: AppColors.white)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    email,
                                    style: AppTextStyles.body2.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: AppColors.textSubtle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'PREFERENCES',
                children: [
                  _SettingsRow(
                    icon: Icons.notifications_none,
                    label: 'Notifications',
                    onTap: () => context.push(AppRouter.notificationPreferences),
                  ),
                  _SettingsRow(
                    icon: Icons.lock_outline,
                    label: 'Privacy',
                    onTap: () => context.push(AppRouter.privacySettings),
                  ),
                  _SettingsRow(
                    icon: Icons.palette_outlined,
                    label: 'Appearance',
                    onTap: () => context.push(AppRouter.appearanceSettings),
                  ),
                  _SettingsRow(
                    icon: Icons.language,
                    label: 'Language',
                    onTap: () => context.push(AppRouter.languageSettings),
                  ),
                  _SettingsRow(
                    icon: Icons.accessibility_new,
                    label: 'Accessibility',
                    onTap: () => context.push(AppRouter.accessibilitySettings),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'ACCOUNT',
                children: [
                  _SettingsRow(
                    icon: Icons.key_outlined,
                    label: 'Change Password',
                    onTap: () => context.push(AppRouter.changePassword),
                  ),
                  _SettingsRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    onTap: () => context.push(AppRouter.emailSettings),
                  ),
                  _SettingsRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    onTap: () => context.push(AppRouter.phoneSettings),
                  ),
                  _SettingsRow(
                    icon: Icons.security,
                    label: 'Two-Factor Auth',
                    onTap: () => context.push(AppRouter.twoFactorAuth),
                  ),
                  _SettingsRow(
                    icon: Icons.devices,
                    label: 'Active Sessions',
                    onTap: () => context.push(AppRouter.activeSessions),
                  ),
                  _SettingsRow(
                    icon: Icons.link,
                    label: 'Connected Apps',
                    onTap: () => context.push(AppRouter.connectedApps),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'SUBSCRIPTION',
                children: [
                  _SettingsRow(
                    icon: Icons.star_border,
                    label: 'Current Plan: Free',
                    onTap: () => context.push(AppRouter.subscription),
                  ),
                  _SettingsRow(
                    icon: Icons.receipt_long,
                    label: 'Billing History',
                    onTap: () => context.push(AppRouter.billingHistory),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'DATA',
                children: [
                  _SettingsRow(
                    icon: Icons.download_outlined,
                    label: 'Export My Data',
                    onTap: () => context.push(AppRouter.dataExport),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline,
                    label: 'Data Export Status',
                    onTap: () => context.push(AppRouter.dataExportStatus),
                  ),
                  _SettingsRow(
                    icon: Icons.share_outlined,
                    label: 'Download My Data',
                    onTap: () => context.push(AppRouter.downloadMyData),
                  ),
                  _SettingsRow(
                    icon: Icons.delete_outline,
                    label: 'Delete Account',
                    isDanger: true,
                    onTap: () => context.push(AppRouter.accountDeletion),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'SUPPORT',
                children: [
                  _SettingsRow(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () => context.push(AppRouter.helpSupport),
                  ),
                  _SettingsRow(
                    icon: Icons.bug_report_outlined,
                    label: 'Report a Problem',
                    onTap: () => context.push(AppRouter.reportProblem),
                  ),
                  _SettingsRow(
                    icon: Icons.lightbulb_outline,
                    label: 'Feedback',
                    onTap: () => context.push(AppRouter.feedback),
                  ),
                  _SettingsRow(
                    icon: Icons.card_giftcard,
                    label: 'Invite a Friend',
                    onTap: () => context.push(AppRouter.referral),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'ABOUT',
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline,
                    label: 'About Cozy Health',
                    onTap: () => context.push(AppRouter.about),
                  ),
                  _SettingsRow(
                    icon: Icons.description_outlined,
                    label: 'Legal',
                    onTap: () => context.push(AppRouter.legalHub),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Logout button
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Log out?',
                            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
                          ),
                          content: Text(
                            'You\'ll need to log in again.',
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
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await LocalDbService().clearAllUserData();
                                if (context.mounted) {
                                  context.go(AppRouter.login);
                                }
                              },
                              child: Text(
                                'Log out',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Text(
                      'Log out',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Version 1.0.0 (build 42)',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.body2.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: List.generate(
              children.length,
              (index) {
                final isLast = index == children.length - 1;
                return Column(
                  children: [
                    children[index],
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 56),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border.withValues(alpha: 0.4),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDanger;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.isDanger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.text;
    final iconColor = isDanger ? AppColors.danger : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: isDanger ? AppColors.danger : AppColors.textSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
