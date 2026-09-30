import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

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
              3.sh,

              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left,
                          size: 22,
                          color: AppColors.darkGrey,
                        ),
                        Text(
                          'Back',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Privacy Settings',
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                ],
              ),

              5.sh,

              _privacyTile(
                icon: Icons.person_outline,
                title: 'Manage your account',
                subtitle: 'Choose and control your\nprivacy options',
                onTap: () {},
              ),

              Padding(
                padding: EdgeInsets.only(left: 11.w),
                child: const Divider(
                  color: Color(0xFFE5E7EB),
                  height: 24,
                ),
              ),

              _privacyTile(
                icon: Icons.delete_outline,
                title: 'Delete my account',
                subtitle:
                    'Permanently delete your account and\nany data associated with it, including\ncycle and health-related data.',
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _privacyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.2.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: AppColors.darkGrey,
            ),
            5.sw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                  0.8.sh,
                  Text(
                    subtitle,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 13,
                      color: AppColors.darkGrey,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}