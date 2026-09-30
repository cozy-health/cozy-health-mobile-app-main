import 'package:cozy_health/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../gen/assets.gen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Cozy Community', style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Tabs
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTab('All Posts', true),
                  3.sw,
                  _buildTab('Anxiety', false),
                  3.sw,
                  _buildTab('Depression', false),
                  3.sw,
                  _buildTab('Trauma', false),
                ],
              ),
            ),
          ),

          4.sh,

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              children: [
                _buildPost(
                  name: 'Cordelia',
                  time: '2hr ago',
                  tag: 'Anxiety',
                  content: 'Feeling overwhelmed lately. Anyone else experiencing increased anxiety due to work pressure?',
                  likes: 50,
                  comments: 100,
                ),
                4.sh,
                _buildPost(
                  name: 'Cordelia',
                  time: '2hr ago',
                  tag: 'Grief',
                  content: 'Feeling overwhelmed lately. Anyone else experiencing increased anxiety due to work pressure?',
                  likes: 50,
                  comments: 100,
                ),

                6.sh,

                // Featured Groups
                Text('Featured Groups', style: AppTextStyles.heading2),
                3.sh,

                _buildGroupCard(
                  title: 'Anxiety Group',
                  members: '100 members',
                  description: 'A safe space to share experiences and coping strategies for anxiety.',
                  color: AppColors.primary,
                  isJoined: true,
                ),
                3.sh,
                _buildGroupCard(
                  title: 'Suicide Group',
                  members: '500 members',
                  description: 'A safe space to share experiences and coping strategies for suicide.',
                  color: const Color(0xFFEF5350),
                  isJoined: false,
                ),
                3.sh,
                _buildGroupCard(
                  title: 'Trauma Group',
                  members: '500 members',
                  description: 'A safe space to share experiences and coping strategies for trauma.',
                  color: const Color(0xFF4CAF50),
                  isJoined: false,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/new-post'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: AppTextStyles.body2.copyWith(
          color: isActive ? AppColors.white : AppColors.grey,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildPost({
    required String name,
    required String time,
    required String tag,
    required String content,
    required int likes,
    required int comments,
  }) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Text('👩‍🦰', style: TextStyle(fontSize: 20)),
              ),
              3.sw,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.heading2.copyWith(fontSize: 16)),
                  Text(time, style: AppTextStyles.body2.copyWith(color: AppColors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(tag, style: AppTextStyles.body2.copyWith(color: const Color(0xFF2E7D32), fontSize: 12)),
              ),
            ],
          ),
          4.sh,
          Text(content, style: AppTextStyles.body1),
          4.sh,
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 20, color: AppColors.grey),
              2.sw,
              Text('$comments', style: AppTextStyles.body2),
              6.sw,
              const Icon(Icons.favorite_border, size: 20, color: AppColors.grey),
              2.sw,
              Text('$likes', style: AppTextStyles.body2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard({
    required String title,
    required String members,
    required String description,
    required Color color,
    required bool isJoined,
  }) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.midGrey),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: color, size: 28),
              3.sw,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading2),
                  Text(members, style: AppTextStyles.body2.copyWith(color: AppColors.grey)),
                ],
              ),
            ],
          ),
          3.sh,
          Text(description, style: AppTextStyles.body1),
          4.sh,
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: isJoined ? 'Joined' : 'Join group',
              onPressed: () {},
              isOutlined: isJoined,
            ),
          ),
        ],
      ),
    );
  }
}