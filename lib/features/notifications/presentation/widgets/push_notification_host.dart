import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/models/app_notification.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import 'notification_permission_sheet.dart';

class PushNotificationHost extends StatefulWidget {
  const PushNotificationHost({super.key, required this.child});
  final Widget child;
  @override
  State<PushNotificationHost> createState() => _PushNotificationHostState();
}

class _PushNotificationHostState extends State<PushNotificationHost> {
  StreamSubscription<AppNotification>? _subscription;
  StreamSubscription<void>? _accountSubscription;
  StreamSubscription<dynamic>? _settingsSubscription;
  int _settingsGeneration = 0;
  bool _checking = false;
  bool _offered = false;
  String? _owner;
  @override
  void initState() {
    super.initState();
    _owner = LocalDbService().activeUserId;
    unawaited(_observeTour());
    _subscription = PushNotificationService.instance.foreground.listen((
      notification,
    ) {
      final context = AppRouter.navigatorKey.currentContext;
      if (mounted && context != null && context.mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(
            content: Text('${notification.title}\n${notification.body}'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () =>
                  PushNotificationService.instance.open(notification),
            ),
          ),
        );
      }
    });
    _accountSubscription = LocalDbService().accountChanges.listen((_) {
      if (_owner == LocalDbService().activeUserId) return;
      AppSnackbar.dismiss();
      _owner = LocalDbService().activeUserId;
      unawaited(_observeTour());
      if (mounted) {
        setState(() {
          _offered = false;
        });
      }
    });
    PushNotificationService.instance.addListener(_offer);
    AppRouter.router.routeInformationProvider.addListener(_offer);
  }

  Future<void> _observeTour() async {
    final generation = ++_settingsGeneration;
    await _settingsSubscription?.cancel();
    final settings = await LocalDbService().settingsBox();
    if (!mounted || generation != _settingsGeneration) return;
    _settingsSubscription = settings.watch().listen((event) {
      if (event.key == 'new_account_tour_pending') _offer();
    });
    _offer();
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
        final settings = await LocalDbService().settingsBox();
        if (settings.get('new_account_tour_pending') == true &&
            settings.get('has_seen_tour') != true) {
          return;
        }
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
    _settingsGeneration++;
    _settingsSubscription?.cancel();
    _subscription?.cancel();
    _accountSubscription?.cancel();
    PushNotificationService.instance.removeListener(_offer);
    AppRouter.router.routeInformationProvider.removeListener(_offer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
