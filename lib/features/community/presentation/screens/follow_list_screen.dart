import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../widgets/user_row.dart';

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({super.key});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _following = [
    {
      'username': 'sarahchen',
      'bio': 'Trying to be kinder to myself.',
      'isFollowing': true,
    },
    {'username': 'jordan', 'bio': 'One day at a time.', 'isFollowing': true},
  ];

  final List<Map<String, dynamic>> _followers = [
    {
      'username': 'sarahchen',
      'bio': 'Trying to be kinder to myself.',
      'isFollowing': true,
    },
    {'username': 'mike', 'bio': '', 'isFollowing': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.textMutedDark
              : AppColors.textMutedLight,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: 'Following (${_following.length})'),
            Tab(text: 'Followers (${_followers.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(_following, 'You\'re not following anyone yet.'),
            _buildList(_followers, 'No followers yet. That\'s okay.'),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final user = list[index];
        return UserRow(
          user: user,
          onTap: () => context.push(
            AppRouter.userProfile,
            extra: {'username': user['username']},
          ),
          onFollowToggle: () {
            setState(() {
              user['isFollowing'] = !(user['isFollowing'] as bool);
            });
          },
        );
      },
    );
  }
}
