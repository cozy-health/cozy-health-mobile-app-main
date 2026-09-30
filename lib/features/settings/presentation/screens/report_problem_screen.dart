import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              5.sh,

              Text(
                'Report a problem',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.black,
                ),
              ),

              4.sh,

              _sectionTitle('Account'),

              _settingsTile(
                icon: Icons.person_outline,
                title: 'Edit profile',
                onTap: () => context.push(AppRouter.editProfile),
              ),

              _settingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Security',
                onTap: () => context.push(AppRouter.privacySettings),
              ),

              _settingsTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () {},
              ),

              4.sh,

              _sectionTitle('Support & About'),

              _settingsTile(
                icon: Icons.credit_card_outlined,
                title: 'My Subscription',
                onTap: () {},
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
                onTap: () {},
              ),

              _settingsTile(
                icon: Icons.logout,
                title: 'Log out',
                onTap: () {},
              ),
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
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.black,
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
              size: 23,
              color: AppColors.black,
            ),
            5.sw,
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontSize: 16,
                  color: AppColors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 26,
              color: AppColors.darkGrey,
            ),
          ],
        ),
      ),
    );
  }
}