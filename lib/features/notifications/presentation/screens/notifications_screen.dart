import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import '../../../../core/models/app_notification.dart';
import '../../data/notification_repository.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  void _markAllAsRead() async {
    await NotificationRepository().markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All caught up')));
    }
  }

  void _deleteNotification(AppNotification item) async {
    await NotificationRepository().deleteNotification(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification dismissed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: NotificationRepository().watchNotifications(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final unreadCount = items.where((n) => !n.read).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: _markAllAsRead,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  'Mark all as read',
                  style: AppTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: NotificationRepository().watchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];
            if (items.isEmpty) return _buildEmptyState();
            return _buildList(items);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'You\'re all caught up.',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'When something happens, we\'ll let you know here.',
              style: AppTextStyles.body1.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.push(AppRouter.notificationPreferences),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notification settings',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<AppNotification> items) {
    // Sort items latest first
    final sortedItems = List<AppNotification>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Map<String, List<AppNotification>> grouped = {};
    for (var item in sortedItems) {
      // Very simple grouping logic
      final now = DateTime.now();
      final difference = now.difference(item.createdAt).inDays;
      String group;
      if (difference == 0 && now.day == item.createdAt.day) {
        group = 'Today';
      } else if (difference <= 1) {
        group = 'Yesterday';
      } else {
        group = 'Earlier';
      }
      grouped.putIfAbsent(group, () => []).add(item);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: grouped.length + 1, // +1 for the header
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Notifications',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          final groupIndex = index - 1;
          final dateGroup = grouped.keys.elementAt(groupIndex);
          final items = grouped[dateGroup]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                dateGroup,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildNotificationCard(item),
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    String icon = '🔔';
    if (item.type == 'achievement') icon = '🏆';
    if (item.type == 'check_in') icon = '💛';
    if (item.type == 'comment') icon = '💬';
    if (item.type == 'export') icon = '📄';
    if (item.type == 'security') icon = '🔒';

    final time = DateFormat('h:mm a').format(item.createdAt);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(item),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: GestureDetector(
        onTap: () async {
          await NotificationRepository().markAsRead(item.id);
          if (item.type == 'achievement' && mounted) {
            context.push(AppRouter.notificationDetail);
          } else {
            // Navigation to other routes based on type
          }
        },
        onLongPress: () {
          // Context menu (simulated with a bottom sheet for now)
          showModalBottomSheet(
            context: context,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      title: Text(
                        'Mark as read',
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onTap: () async {
                        await NotificationRepository().markAsRead(item.id);
                        if (!context.mounted) return;
                        if (mounted) context.pop();
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline,
                        color: AppColors.danger,
                      ),
                      title: Text(
                        'Delete',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                      onTap: () {
                        context.pop();
                        _deleteNotification(item);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            color: item.read
                ? AppColors.surface
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: item.read ? Colors.transparent : Theme.of(context).colorScheme.primary,
                width: 3,
              ),
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: item.read ? 1 : 0,
              ),
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: item.read ? 1 : 0,
              ),
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: item.read ? 1 : 0,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(icon, style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: AppTextStyles.body1.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: item.read
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: AppTextStyles.body2.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    time,
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSubtleDark
                          : AppColors.textSubtleLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (!item.read)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
