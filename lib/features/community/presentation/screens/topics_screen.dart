import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../community_theme.dart';

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
      backgroundColor: context.communityBackground,
      appBar: AppBar(
        backgroundColor: context.communityBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Topics', style: context.communityHeading3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: _topics.length,
          separatorBuilder: (_, __) => SizedBox(height: 12),
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.communityBorder.withValues(alpha: 0.7),
                  ),
                ),
                child: Row(
                  children: [
                    Text(topic['icon'], style: TextStyle(fontSize: 28)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(topic['title'], style: context.communityHeading3),
                          SizedBox(height: 2),
                          Text(
                            '${topic['posts']} posts',
                            style: context.communityBody2.copyWith(
                              color: context.communityMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: context.communityMuted,
                    ),
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
