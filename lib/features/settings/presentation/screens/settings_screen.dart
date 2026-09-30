import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
  child: SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 5.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        5.sh,

        Text(
          'Settings',
          style: AppTextStyles.heading1.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.darkGrey,
          ),
        ),

        3.sh,

        _sectionTitle('Account'),

        _settingsTile(
          icon: Icons.person_outline,
          title: 'Edit profile',
          onTap: () => context.push(AppRouter.editProfile),
        ),

        _settingsTile(
          icon: Icons.medical_services_outlined,
          title: 'Provider / Therapist',
          onTap: () => context.push(AppRouter.provider),
        ),

        _settingsTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy settings',
          onTap: () => context.push(AppRouter.privacySettings),
        ),

        4.sh,

        _sectionTitle('Support & About'),

        _settingsTile(
          icon: Icons.credit_card_outlined,
          title: 'My Subscription',
          onTap: () => context.push(AppRouter.subscription),
        ),

        _settingsTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () => context.push(AppRouter.helpSupport),
        ),

        _settingsTile(
          icon: Icons.article_outlined,
          title: 'Terms and Policies',
          onTap: () => context.push(AppRouter.termsPolicies),
        ),

        4.sh,

        _sectionTitle('Actions'),

        _settingsTile(
          icon: Icons.flag_outlined,
          title: 'Report a problem',
          onTap: () => context.push(AppRouter.reportProblem),
        ),

        _settingsTile(
          icon: Icons.logout,
          title: 'Log out',
          onTap: () {},
        ),

        4.sh,
      ],
    ),
  ),
),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.2.h),
      child: Text(
        title,
        style: AppTextStyles.body1.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.darkGrey,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: EdgeInsets.symmetric(horizontal: 3.w),
        decoration: const BoxDecoration(
          color: Color(0xFFF3F5FA),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.darkGrey,
            ),
            5.sw,
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontSize: 15,
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 25,
              color: AppColors.darkGrey,
            ),
          ],
        ),
      ),
    );
  }
}