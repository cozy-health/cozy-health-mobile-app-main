import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../utils/responsive_extensions.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For demo purposes - you can make this dynamic later
    final bool hasNotifications = true;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
      ),
      body: hasNotifications
          ? _buildNotificationsList()
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            Assets.svg.noNotification,
            width: 120,
            height: 120,
          ),
          6.sh,
          Text(
            'No new notifications for now.\nCheck back later',
            style: AppTextStyles.body1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 12),
      children: [
        // Mood Check-in Card
        _buildNotificationCard(
          icon: '😊',
          title: 'Mood Check-in',
          description:
          'It’s time to check in! How are you feeling today?\nA few words can make a difference',
          actionText: 'Check-in Mood',
          color: const Color(0xFFFFF4E5), // Light peach
          onTap: () {
            // Navigate to Mood Check-in flow
          },
        ),
        4.sh,

        // Journaling Card
        _buildNotificationCard(
          icon: '💭',
          title: 'Journaling',
          description:
          'Gentle reminder: Journaling can help reduce stress.\nLet’s reflect on your day!',
          actionText: 'Start Journaling',
          color: AppColors.lightGrey,
          onTap: () {
            // Navigate to Journaling
          },
        ),
        4.sh,

        // Mental Health Quiz Card
        _buildNotificationCard(
          icon: '🧠',
          title: 'Mental Health Quiz',
          description:
          'Hey there! Don’t forget your self-assessment.\nIt’s been 7 days since your last check-in',
          actionText: 'Take self-assessment quiz',
          color: AppColors.lightGrey,
          onTap: () {
            // Navigate to Quiz
          },
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required String icon,
    required String title,
    required String description,
    required String actionText,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                3.w.sw,
                Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                ),
              ],
            ),
            3.sh,
            Text(
              description,
              style: AppTextStyles.body1,
            ),
            4.sh,
            Text(
              '$actionText →',
              style: AppTextStyles.linkText.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}