import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../data/notification_repository.dart';

/// Home and Community share the same account-scoped inbox and unread state.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, this.notifications});
  final Stream<List<AppNotification>>? notifications;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<AppNotification>>(
    stream: notifications ?? NotificationRepository().watchNotifications(),
    builder: (context, snapshot) {
      final unread = (snapshot.data ?? []).where((n) => !n.read).length;
      return Tooltip(
        message: unread == 0
            ? 'Notifications'
            : 'Notifications: $unread unread',
        excludeFromSemantics: true,
        child: AppPressable(
          key: const ValueKey('notification-bell'),
          label: unread == 0
              ? 'Notifications'
              : 'Notifications, $unread unread',
          onPressed: () => context.push(AppRouter.notifications),
          child: SizedBox(
            width: context.cozyColors.wellness.touch,
            height: context.cozyColors.wellness.touch,
            child: Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  children: [
                    SvgPicture.asset(
                      'assets/svg/home_notification_bell.svg',
                      width: 30,
                      height: 30,
                      excludeFromSemantics: true,
                    ),
                    if (unread > 0)
                      const Positioned(
                        left: 16,
                        top: 4,
                        child: DecoratedBox(
                          key: ValueKey('notification-unread-dot'),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 8, height: 8),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
