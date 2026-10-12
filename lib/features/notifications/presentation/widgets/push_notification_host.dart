import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/push_notification_service.dart';
import 'app_notification_banner.dart';
import 'notification_permission_sheet.dart';

class PushNotificationHost extends StatefulWidget {
  const PushNotificationHost({super.key, required this.child});
  final Widget child;
  @override
  State<PushNotificationHost> createState() => _PushNotificationHostState();
}

class _PushNotificationHostState extends State<PushNotificationHost> {
  AppNotification? _notification;
  StreamSubscription<AppNotification>? _subscription;
  StreamSubscription<void>? _accountSubscription;
  bool _checking = false;
  bool _offered = false;
  String? _owner;
  @override
  void initState() {
    super.initState();
    _owner = LocalDbService().activeUserId;
    _subscription = PushNotificationService.instance.foreground.listen((
      notification,
    ) {
      if (mounted) setState(() => _notification = notification);
    });
    _accountSubscription = LocalDbService().accountChanges.listen((_) {
      if (_owner == LocalDbService().activeUserId) return;
      _owner = LocalDbService().activeUserId;
      if (mounted) {
        setState(() {
          _notification = null;
          _offered = false;
        });
      }
    });
    PushNotificationService.instance.addListener(_offer);
    AppRouter.router.routeInformationProvider.addListener(_offer);
  }

  void _offer() {
    if (_checking ||
        _offered ||
        !mounted ||
        AppRouter.router.routeInformationProvider.value.uri.path !=
            AppRouter.home) {
      return;
    }
    _checking = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final owner = LocalDbService().activeUserId;
        final eligible = await PushNotificationService.instance.shouldPrompt();
        final context = AppRouter.navigatorKey.currentContext;
        if (!mounted ||
            owner != LocalDbService().activeUserId ||
            context == null ||
            !context.mounted ||
            !eligible) {
          return;
        }
        _offered = true;
        await NotificationPermissionSheet.show(context);
      } finally {
        _checking = false;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _accountSubscription?.cancel();
    PushNotificationService.instance.removeListener(_offer);
    AppRouter.router.routeInformationProvider.removeListener(_offer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_notification case final notification?)
        AppNotificationBanner(
          key: ValueKey(notification.id),
          icon: '🔔',
          title: notification.title,
          body: notification.body,
          onTap: () => PushNotificationService.instance.open(notification),
          onDismiss: () {
            if (mounted && _notification?.id == notification.id) {
              setState(() => _notification = null);
            }
          },
        ),
    ],
  );
}
