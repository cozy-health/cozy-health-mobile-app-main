import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../gen/assets.gen.dart';

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Your Journal',
          style: AppTextStyles.heading2,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () {
              // Navigate to new journal entry screen
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        children: [
          _buildJournalEntry(
            title: 'A Lovely Day',
            date: 'Today, 8:30pm',
            content:
                'Today felt like a whirlwind. The morning started off rough — I woke up feeling anxious and a bit out of sorts. Work was overwhelming, with endless emails ...',
          ),
          4.sh,
          _buildJournalEntry(
            title: 'A Lovely Day',
            date: 'Yesterday, 4:30pm',
            content:
                'Today felt like a whirlwind. The morning started off rough — I woke up feeling anxious and a bit out of sorts. Work was overwhelming, with endless emails ...',
          ),
          4.sh,
          _buildJournalEntry(
            title: 'A Lovely Day',
            date: '11/04/05, 4:30pm',
            content:
                'Today felt like a whirlwind. The morning started off rough — I woke up feeling anxious and a bit out of sorts. Work was overwhelming, with endless emails ...',
          ),
          4.sh,
          _buildJournalEntry(
            title: 'A Lovely Day',
            date: '25/10/25, 4:30pm',
            content:
                'Today felt like a whirlwind. The morning started off rough — I woke up feeling anxious and a bit out of sorts. Work was overwhelming, with endless emails ...',
          ),
          4.sh,
          _buildJournalEntry(
            title: 'A Lovely Day',
            date: '25/10/25, 4:30pm',
            content:
                'Today felt like a whirlwind. The morning started off rough — I woke up feeling anxious and a bit out of sorts. Work was overwhelming, with endless emails ...',
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry({
    required String title,
    required String date,
    required String content,
  }) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              const Icon(Icons.more_horiz, color: AppColors.grey),
            ],
          ),
          1.sh,
          Text(
            date,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey, fontSize: 13),
          ),
          3.sh,
          Text(
            content,
            style: AppTextStyles.body1.copyWith(height: 1.5),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}