import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../community_theme.dart';

class FeaturedPostsScreen extends StatelessWidget {
  const FeaturedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.communityBackground,
      appBar: AppBar(
        backgroundColor: context.communityBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.communityText),
          onPressed: () => context.pop(),
        ),
        title: Text('Featured', style: context.communityHeading3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('This week', style: context.communityHeading2),
              SizedBox(height: 16),
              _buildFeaturedCard(
                context: context,
                username: 'sarahchen',
                content: '"Small wins are still wins."',
                likes: 128,
                comments: 22,
                isPrimary: true,
              ),
              SizedBox(height: 12),
              _buildFeaturedCard(
                context: context,
                username: 'mike',
                content: '"I made it through today."',
                likes: 94,
                comments: 15,
                isPrimary: false,
              ),
              SizedBox(height: 48),

              Text('From the team', style: context.communityHeading2),
              SizedBox(height: 16),
              Text(
                'These posts moved us this week.\nWe hope they reach someone who needs them.',
                style: context.communityBody1.copyWith(
                  color: context.communityMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCard({
    required BuildContext context,
    required String username,
    required String content,
    required int likes,
    required int comments,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrimary
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : context.communitySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : context.communityBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPrimary) ...[
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).colorScheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Featured',
                  style: context.communityBody2.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
          ],
          Text(
            content,
            style: context.communityHeading3.copyWith(
              fontFamily: 'Georgia',
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '— @$username',
            style: context.communityBody1.copyWith(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 24),
          Row(
            children: [
              _buildReaction(context, Icons.favorite_border, likes),
              SizedBox(width: 24),
              _buildReaction(context, Icons.chat_bubble_outline, comments),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReaction(BuildContext context, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.communityMuted),
        SizedBox(width: 6),
        Text(
          count.toString(),
          style: context.communityBody2.copyWith(
            color: context.communityMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
