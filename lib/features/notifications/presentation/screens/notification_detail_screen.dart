import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/notification_repository.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({super.key, this.notification});
  final AppNotification? notification;

  @override
  Widget build(BuildContext context) {
    final item = notification;
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: item == null
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'This notification is no longer available.',
            )
          : StreamBuilder<List<AppNotification>>(
              stream: NotificationRepository().watchNotifications(),
              builder: (context, snapshot) {
                final current =
                    (snapshot.data ?? [])
                        .where((row) => row.id == item.id)
                        .firstOrNull ??
                    item;
                final theme = Theme.of(context);
                final destination = switch (current.type) {
                  'reply' || 'like' => AppRouter.communityHub,
                  'crisis' => AppRouter.crisisHub,
                  'journal' => AppRouter.journal,
                  _ => AppRouter.moodHistory,
                };
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(current.title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    Text(current.body, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    Text(
                      MaterialLocalizations.of(
                        context,
                      ).formatMediumDate(current.createdAt.toLocal()),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.push(destination),
                      child: const Text('View related activity'),
                    ),
                    if (!current.read)
                      OutlinedButton(
                        onPressed: () =>
                            NotificationRepository().markAsRead(current.id),
                        child: const Text('Mark as read'),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
