import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../community_theme.dart';

class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        title: Text('Moderation', style: context.communityHeading3),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: context.communityMuted,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Open (2)'),
            Tab(text: 'Reviewing (0)'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOpenQueue(),
            _buildEmpty('No items in review.'),
            _buildEmpty('No recently resolved items.'),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenQueue() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        _buildReportedPostCard(),
        SizedBox(height: 16),
        _buildReportedUserCard(),
      ],
    );
  }

  Widget _buildReportedPostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.communityBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text(
                'Reported Post',
                style: context.communityBody1.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"I am so tired of everything..."',
            style: context.communityBody1.copyWith(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 12),
          Text('Reported by 2 users', style: context.communityBody2),
          Text('Reasons: Encourages harm', style: context.communityBody2),
          Text(
            'Posted 4h ago',
            style: context.communityBody2.copyWith(
              color: context.communityMuted,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: Text('Hide')),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: Text('Dismiss')),
              ),
            ],
          ),
          SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text('Warn Author'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportedUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.communityBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_off, color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Reported User',
                style: context.communityBody1.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '@username',
            style: context.communityBody1.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('Reported by 1 user', style: context.communityBody2),
          Text('Reasons: Harassment', style: context.communityBody2),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text('View Profile'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () {}, child: Text('Dismiss')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Text(
        message,
        style: context.communityBody1.copyWith(
          color: context.communityMuted,
        ),
      ),
    );
  }
}
