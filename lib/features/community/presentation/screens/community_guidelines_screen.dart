import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../community_theme.dart';

class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

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
        title: Text('Guidelines', style: context.communityHeading3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0E6), Color(0xFFFFE4D6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(24),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Our community\nguidelines',
                  style: context.communityHeading1.copyWith(fontSize: 28),
                ),
              ),
              SizedBox(height: 32),

              _buildGuideline(
                context,
                '💛',
                'Be kind.',
                'Everyone here is going through something. Assume good intent. Speak to people the way you\'d want to be spoken to on your hardest day.',
              ),
              _buildGuideline(
                context,
                '🤝',
                'Be honest.',
                'Share what\'s real for you. You don\'t have to perform wellness or hide struggle. Both are welcome.',
              ),
              _buildGuideline(
                context,
                '🛡',
                'Be safe.',
                'Don\'t encourage harm — to yourself or others. If you\'re in crisis, we have support for you. If someone else is, help them find it.',
              ),
              _buildGuideline(
                context,
                '🔒',
                'Be private.',
                'What\'s shared here stays here. Don\'t screenshot, share, or repost. Don\'t share anyone\'s personal information.',
              ),
              _buildGuideline(
                context,
                '📍',
                'Be here.',
                'This isn\'t a place to sell, promote, recruit, or recruit for anything. It\'s a place to be human with other humans.',
              ),
              _buildGuideline(
                context,
                '🎁',
                'Be generous.',
                'If you have the energy, support someone. A kind reply goes further than you think.',
              ),
              _buildGuideline(
                context,
                '⏳',
                'Be patient.',
                'Moderators are human. Reports take time to process. We get to them.',
              ),

              SizedBox(height: 32),
              Divider(color: context.communityBorder),
              SizedBox(height: 32),

              Text('What gets you removed', style: context.communityHeading2),
              SizedBox(height: 16),
              _buildBullet(context, 'Harassment, hate speech, or threats'),
              _buildBullet(
                context,
                'Content that encourages self-harm or eating disorders',
              ),
              _buildBullet(context, 'Sharing someone\'s private information'),
              _buildBullet(context, 'Spam, scams, or promotional content'),
              _buildBullet(context, 'Sexual content involving minors'),
              _buildBullet(context, 'Impersonation'),

              SizedBox(height: 32),
              Divider(color: context.communityBorder),
              SizedBox(height: 32),

              Text(
                'What happens if you\'re reported',
                style: context.communityHeading2,
              ),
              SizedBox(height: 16),
              Text(
                'We look at every report. Depending on what we find:\n\n'
                '• A warning and reminder of guidelines\n'
                '• Temporary suspension (3–30 days)\n'
                '• Permanent removal\n\n'
                'You can appeal any decision by emailing appeals@cozyhealth.app.',
                style: context.communityBody1.copyWith(height: 1.5),
              ),

              SizedBox(height: 32),
              Divider(color: context.communityBorder),
              SizedBox(height: 32),

              Text('If you\'re in crisis', style: context.communityHeading2),
              SizedBox(height: 16),
              Text(
                'Posting about it is okay. We care. And we\'ll also send you resources. You don\'t have to go through this alone.',
                style: context.communityBody1.copyWith(height: 1.5),
              ),
              SizedBox(height: 24),

              GestureDetector(
                onTap: () => context.push(AppRouter.crisisHub),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View crisis resources',
                        style: context.communityBody1.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideline(BuildContext context, String icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.communitySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.communityBorder.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Text(title, style: context.communityHeading3),
            ],
          ),
          SizedBox(height: 12),
          Text(
            body,
            style: context.communityBody1.copyWith(
              height: 1.5,
              color: context.communityText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 18, color: context.communityText)),
          Expanded(
            child: Text(
              text,
              style: context.communityBody1.copyWith(
                height: 1.5,
                color: context.communityText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
