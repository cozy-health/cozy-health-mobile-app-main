import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  final List<Map<String, dynamic>> _topics = const [
    {'icon': '💛', 'title': 'Anxiety', 'posts': '1,240'},
    {'icon': '🌙', 'title': 'Sleep', 'posts': '890'},
    {'icon': '👥', 'title': 'Relationships', 'posts': '620'},
    {'icon': '🌿', 'title': 'Self-compassion', 'posts': '540'},
    {'icon': '💼', 'title': 'Work & Life', 'posts': '410'},
    {'icon': '🕊', 'title': 'Grief & Loss', 'posts': '320'},
    {'icon': '🧘', 'title': 'Mindfulness', 'posts': '290'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Topics', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _topics.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final topic = _topics[index];
            return GestureDetector(
              onTap: () {
                // In a real app this might navigate to CommunityHub with this filter selected
                context.push(AppRouter.communityHub);
              },
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Text(topic['icon'], style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(topic['title'], style: AppTextStyles.heading3),
                          const SizedBox(height: 2),
                          Text('${topic['posts']} posts', style: AppTextStyles.body2.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
