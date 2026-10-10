import '../../../../core/services/user_data_fetcher.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(content: Text('All caught up')),
      );
    }
  }

  void _deleteNotification(AppNotification item) async {
    await NotificationRepository().deleteNotification(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
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
        centerTitle: true,
        title: Text(
          'Notifications',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: NotificationRepository().watchNotifications(),
            initialData: NotificationRepository().currentEntries(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final unreadCount = items.where((n) => !n.read).length;
              if (unreadCount == 0) return const SizedBox.shrink();

              return IconButton(
                tooltip: 'Mark all as read',
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.done_all),
                color: Theme.of(context).colorScheme.primary,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<AppNotification>>(
          stream: NotificationRepository().watchNotifications(),
          initialData: NotificationRepository().currentEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const ListSkeleton();
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
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: theme.brightness == Brightness.dark
              ? AppColors.accentSkyDark
              : AppColors.accentSky,
        ),
      ),
      child: EmptyState(
        onOfflineRetry: () => UserDataFetcher().fetchNotifications(),
        icon: Icons.notifications_none,
        title: 'No new notifications for now. Check back later',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final dateGroup = grouped.keys.elementAt(index);
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
          if (mounted) {
            context.push(
              AppRouter.notificationDetail,
              extra: item.copyWith(read: true),
            );
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
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: item.read
                  ? Theme.of(context).dividerColor
                  : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .25),
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
