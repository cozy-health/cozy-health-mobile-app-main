import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/app_notification.dart';

/// One-off internal tests, independent of the server reminder scheduler.
class PhoneNotificationTestService {
  PhoneNotificationTestService({
    required this.enabled,
    required this.currentOwner,
    required this.allowed,
    required this.onOpen,
    this.affirmation,
    FlutterLocalNotificationsPlugin? plugin,
    DateTime Function()? now,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _now = now ?? DateTime.now;

  final bool enabled;
  final String? Function() currentOwner;
  final Future<bool> Function() allowed;
  final void Function(AppNotification) onOpen;
  final Future<String?> Function()? affirmation;
  static const fallbackAffirmation =
      'Small steps count. You can move at your own pace.';
  final FlutterLocalNotificationsPlugin _plugin;
  final DateTime Function() _now;
  static const categories = ['mood', 'journal', 'streak', 'affirmation'];
  static const delay = Duration(seconds: 10);
  static const channelId = 'cozy_phone_tests_v1';
  Future<void>? _initializing;
  int _generation = 0;

  Future<void> initialize() {
    if (!enabled) return Future.value();
    return _initializing ??= _initialize().catchError((Object error) {
      _initializing = null;
      throw error;
    });
  }

  Future<void> _initialize() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          handleTap(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      handleTap(launch?.notificationResponse?.payload);
    }
  }

  Future<String> schedule(String category) async {
    if (!enabled) return 'Phone tests are available only in internal builds.';
    final index = categories.indexOf(category);
    final owner = currentOwner();
    final generation = _generation;
    if (index < 0 || owner == null) {
      return 'Sign in before testing a notification.';
    }
    try {
      if (!await allowed()) {
        return 'Enable phone alerts before running this test.';
      }
      await initialize();
      String? affirmationBody;
      if (category == 'affirmation') {
        try {
          affirmationBody = await affirmation?.call();
        } catch (_) {
          /* Use gentle offline copy. */
        }
      }
      if (owner != currentOwner() || generation != _generation) {
        return 'Account changed. Please try again.';
      }
      final created = _now().toUtc();
      await _plugin.zonedSchedule(
        id: 970180 + index,
        title: category == 'affirmation'
            ? 'Your Cozy affirmation'
            : 'Cozy Health: test $category reminder',
        body: category == 'affirmation'
            ? (affirmationBody?.trim().isNotEmpty == true
                  ? affirmationBody!.trim()
                  : fallbackAffirmation)
            : 'Your phone notification test is ready. Tap to open Cozy Health.',
        scheduledDate: tz.TZDateTime.from(created.add(delay), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'Cozy phone notification tests',
            channelDescription: 'Manually requested internal phone tests',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('cozy_notification'),
            visibility: NotificationVisibility.private,
          ),
          iOS: DarwinNotificationDetails(
            sound: 'cozy_notification.wav',
            presentAlert: true,
            presentBanner: true,
            presentList: true,
            presentSound: true,
            presentBadge: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({
          'kind': 'cozy_phone_test',
          'user_id': owner,
          'category': category,
          'created_at': created.toIso8601String(),
        }),
      );
      if (owner != currentOwner() || generation != _generation) {
        await _plugin.cancel(id: 970180 + index);
        return 'Account changed. Test cancelled.';
      }
      return 'Test scheduled. Lock your phone now. iPhone delivery is in about 10 seconds; Android may take longer.';
    } catch (_) {
      return 'Could not schedule the phone test. Please try again.';
    }
  }

  void handleTap(String? raw) {
    if (!enabled || raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final created = DateTime.parse(data['created_at'] as String).toUtc();
      final age = _now().toUtc().difference(created);
      if (data['kind'] != 'cozy_phone_test' ||
          data['user_id'] != currentOwner() ||
          currentOwner() == null ||
          !categories.contains(data['category']) ||
          age.isNegative ||
          age > const Duration(hours: 1)) {
        return;
      }
      onOpen(
        AppNotification(
          id: 'phone-test-${data['category']}-${created.microsecondsSinceEpoch}',
          title: 'Cozy Health phone test',
          body: 'Internal phone notification test',
          type: data['category'] as String,
          read: false,
          payload: {'user_id': data['user_id'], 'simulation': true},
          createdAt: created,
        ),
      );
    } catch (_) {
      /* Ignore malformed or unrelated payloads. */
    }
  }

  Future<void> cancel() async {
    _generation++;
    if (!enabled || _initializing == null) return;
    try {
      await _initializing;
      for (var i = 0; i < categories.length; i++) {
        await _plugin.cancel(id: 970180 + i);
      }
    } catch (_) {
      /* Missing native support must not block logout. */
    }
  }
}
