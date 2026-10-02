import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text('Moderation', style: AppTextStyles.heading3),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
          indicatorColor: AppColors.primary,
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
        border: Border.all(color: AppColors.border),
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
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"I am so tired of everything..."',
            style: AppTextStyles.body1.copyWith(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 12),
          Text('Reported by 2 users', style: AppTextStyles.body2),
          Text('Reasons: Encourages harm', style: AppTextStyles.body2),
          Text(
            'Posted 4h ago',
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
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
        border: Border.all(color: AppColors.border),
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
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '@username',
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('Reported by 1 user', style: AppTextStyles.body2),
          Text('Reasons: Harassment', style: AppTextStyles.body2),
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
        style: AppTextStyles.body1.copyWith(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
        ),
      ),
    );
  }
}
