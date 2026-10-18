import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../api/api_client.dart';
import '../api/api_transport.dart';
import '../api/leaf_pin_policy.dart';
import '../api/network_build_policy.dart';
import '../constants/api_constants.dart';
import '../data/demo_mode.dart';
import '../models/app_notification.dart';
import '../routing/app_router.dart';
import '../storage/token_storage.dart';
import '../../features/settings/data/profile_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import 'feature_flags_service.dart';
import 'local_db_service.dart';
import 'notification_permission_controller.dart';
import 'phone_notification_test_service.dart';
import '../repositories/affirmation_repository.dart';

class PushNotificationService extends ChangeNotifier
    with WidgetsBindingObserver {
  PushNotificationService._() {
    phonePermission.addListener(notifyListeners);
  }
  static final instance = PushNotificationService._();
  static const internalBuild = bool.fromEnvironment('INTERNAL_TEST_BUILD');
  static const iosPushEnabled = bool.fromEnvironment('IOS_PUSH_ENABLED');
  static const _secure = FlutterSecureStorage();
  final _local = LocalDbService();
  final _foreground = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get foreground => _foreground.stream;
  final Set<String> _seen = {};
  bool _ready = false;
  bool _busy = false;
  bool _started = false;
  int _generation = 0;
  String status = 'Push delivery is not configured';
  final phonePermission = NotificationPermissionController();
  String get permission => phonePermission.label;
  late final phoneTests = PhoneNotificationTestService(
    enabled: internalBuild,
    currentOwner: () => _local.activeUserId,
    allowed: () async {
      await phonePermission.check();
      return phonePermission.allowed;
    },
    onOpen: open,
    affirmation: () async => (await AffirmationRepository().cached())?.body,
  );
  AppNotification? _pendingTap;
  Timer? _timer;
  String? _registeredSignature;
  Future<void> _cleanupChain = Future.value();
  String? _observedOwner;

  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    TokenStorage.beforeClear = unregisterBeforeLogout;
    _observedOwner = _local.activeUserId;
    _local.accountChanges.listen((_) {
      if (_observedOwner == _local.activeUserId) {
        unawaited(refresh());
        return;
      }
      _observedOwner = _local.activeUserId;
      _generation++;
      _registeredSignature = null;
      _seen.clear();
      _pendingTap = null;
      unawaited(phoneTests.cancel());
      unawaited(refresh());
    });
    FeatureFlagsService.instance.addListener(() => unawaited(refresh()));
    AppRouter.router.routeInformationProvider.addListener(_drainTap);
    try {
      await phoneTests.initialize();
    } catch (_) {
      /* Phone tests must not block startup. */
    }
    try {
      const raw = String.fromEnvironment('FIREBASE_OPTIONS');
      await phonePermission.check();
      if (raw.isEmpty) {
        _setStatus('Push delivery is not configured');
        return;
      }
      final all = jsonDecode(raw) as Map<String, dynamic>;
      final options = Map<String, dynamic>.from(
        all[Platform.isIOS ? 'ios' : 'android'] as Map,
      );
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: options['apiKey'] as String,
          appId: options['appId'] as String,
          messagingSenderId: options['messagingSenderId'] as String,
          projectId: options['projectId'] as String,
          iosBundleId: options['iosBundleId'] as String?,
        ),
      );
      _ready = true;
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      FirebaseMessaging.onMessage.listen(
        (message) => unawaited(_receive(message)),
      );
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => unawaited(_receive(message, tapped: true)),
      );
      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        _registeredSignature = null;
        unawaited(refresh());
      });
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) await _receive(initial, tapped: true);
      _timer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => unawaited(refresh()),
      );
      await refresh();
    } catch (_) {
      _setStatus('Push delivery is unavailable; the app can still be used');
    }
  }

  void _setStatus(String value) {
    status = value;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _timer ??= Timer.periodic(
        const Duration(minutes: 5),
        (_) => unawaited(refresh()),
      );
      unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    final generation = _generation;
    final owner = _local.activeUserId;
    try {
      await phonePermission.check();
      await _cleanupPending();
      if (!_ready) {
        _setStatus(
          'Remote push is not configured. Phone alerts and internal simulations can still be tested.',
        );
        return;
      }
      final profile = _local.getUserProfile();
      final token = await TokenStorage().getToken();
      final authorized = phonePermission.allowed;
      if (owner == null ||
          owner.startsWith('guest_') ||
          token == null ||
          DemoMode.instance.enabled) {
        _setStatus('Sign in to enable reminders');
        return;
      }
      if (profile?.pushConsent != true ||
          profile?.notificationsMaster != true ||
          !authorized) {
        _registeredSignature = null;
        try {
          await ApiClient.instance.delete(
            '/notifications/devices/${await TokenStorage().deviceId()}',
          );
        } catch (_) {}
        _setStatus(
          !authorized
              ? 'Notification permission is $permission'
              : 'Reminders are off',
        );
        return;
      }
      if (Platform.isIOS && !iosPushEnabled) {
        _setStatus(
          'iPhone push awaits Apple Developer signing. Internal simulations are available.',
        );
        return;
      }
      if (!FeatureFlagsService.instance.isEnabled('push_notifications')) {
        _setStatus('Push delivery is temporarily disabled');
        return;
      }
      if (Platform.isIOS &&
          await FirebaseMessaging.instance.getAPNSToken() == null) {
        _setStatus(
          'Apple push registration is unavailable for this installation',
        );
        return;
      }
      final fcm = await FirebaseMessaging.instance.getToken();
      if (fcm == null ||
          generation != _generation ||
          owner != _local.activeUserId) {
        return;
      }
      final signature = '$owner:$fcm';
      if (_registeredSignature != signature) {
        final deviceId = await TokenStorage().deviceId();
        final response = await ApiClient.instance.post(
          '/notifications/register-token',
          data: {
            'device_id': deviceId,
            'platform': Platform.isIOS ? 'ios' : 'android',
            'provider': 'fcm',
            'environment': internalBuild ? 'sandbox' : 'production',
            'token': fcm,
          },
        );
        final registration = {
          'owner': owner,
          'device': deviceId,
          'cleanup_token': response.data['data']['cleanup_token'],
        };
        if (generation != _generation || owner != _local.activeUserId) {
          await _queueCleanup(registration);
          return;
        }
        await _secure.write(
          key: 'push_registration_$owner',
          value: jsonEncode(registration),
        );
        if (generation != _generation || owner != _local.activeUserId) {
          await _queueCleanup(registration);
          await _secure.delete(key: 'push_registration_$owner');
          return;
        }
        _registeredSignature = signature;
      }
      _setStatus('Registered for push delivery');
      _drainTap();
    } catch (_) {
      _setStatus('Push registration could not be completed; it will retry');
    } finally {
      _busy = false;
      if (generation != _generation) unawaited(refresh());
    }
  }

  Future<void> requestPermission({
    bool journal = false,
    bool streak = false,
    bool affirmation = false,
  }) async {
    final owner = _local.activeUserId;
    final generation = _generation;
    try {
      if (!phonePermission.allowed) await phonePermission.request();
      if (owner != _local.activeUserId || generation != _generation) return;
      if (!phonePermission.allowed) {
        _setStatus(
          'Notification permission is $permission. You can change it in phone settings.',
        );
        return;
      }
      final profile = _local.getUserProfile();
      if (profile == null) return;
      await ProfileRepository().saveProfile(
        profile.copyWith(
          pushConsent: true,
          notificationsMaster: true,
          dailyCheckinEnabled: true,
          journalReminderEnabled: journal,
          reminderSettings: {
            ...profile.reminderSettings,
            'streak_enabled': streak,
            'affirmation_enabled': affirmation,
          },
          updatedAt: DateTime.now(),
        ),
      );
      await refresh();
    } catch (_) {
      _setStatus('Notification permission could not be requested');
    }
  }

  static bool shouldOfferPrompt(DateTime? declinedAt, DateTime now) =>
      declinedAt == null ||
      now.difference(declinedAt) >= const Duration(days: 14);

  Future<void> enablePhoneAlerts() async {
    await phonePermission.request();
    await refresh();
  }

  Future<bool> shouldPrompt() async {
    if (!_ready ||
        DemoMode.instance.enabled ||
        _local.getUserProfile()?.pushConsent == true) {
      return false;
    }
    final box = await _local.settingsBox();
    return shouldOfferPrompt(
      DateTime.tryParse(box.get('push_declined_at')?.toString() ?? ''),
      DateTime.now(),
    );
  }

  Future<void> decline() async {
    await (await _local.settingsBox()).put(
      'push_declined_at',
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> unregisterBeforeLogout() async {
    final owner = _local.activeUserId;
    _generation++;
    final generation = _generation;
    _pendingTap = null;
    _registeredSignature = null;
    _seen.clear();
    try {
      await phoneTests.cancel();
      if (owner == null || owner.startsWith('guest_')) return;
      // Secure, account-scoped cleanup survives an offline logout. It never uses the next account's session.
      final raw = await _secure.read(key: 'push_registration_$owner');
      if (raw != null) {
        await _queueCleanup(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
      await _secure.delete(key: 'push_registration_$owner');
      if (_ready && generation == _generation) {
        await FirebaseMessaging.instance.deleteToken();
      }
    } catch (_) {
      /* Retain cleanup; ownership conflicts fail closed. */
    }
  }

  Future<void> _cleanupPending() => _queueCleanup();

  Future<void> _queueCleanup([Map<String, dynamic>? addition]) {
    return _cleanupChain = _cleanupChain.catchError((Object _) {}).then((
      _,
    ) async {
      if (addition != null) {
        final rows =
            jsonDecode(await _secure.read(key: 'push_cleanup') ?? '[]') as List;
        rows.add(addition);
        await _secure.write(key: 'push_cleanup', value: jsonEncode(rows));
      }
      await _performCleanup();
    });
  }

  Future<void> _performCleanup() async {
    final pending =
        jsonDecode(await _secure.read(key: 'push_cleanup') ?? '[]') as List;
    if (pending.isEmpty) return;
    final remaining = <dynamic>[];
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        followRedirects: false,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    dio.httpClientAdapter = createApiTransport(
      LeafPinPolicy(
        host: Uri.parse(ApiConstants.baseUrl).host,
        current: ApiConstants.currentLeafPin,
        next: ApiConstants.nextLeafPin,
      ),
      requirePins: const NetworkBuildPolicy().requirePins,
    );
    try {
      for (final row in pending) {
        try {
          await dio.post(
            '/notifications/cleanup',
            data: {
              'device_id': row['device'],
              'cleanup_token': row['cleanup_token'],
            },
            options: Options(headers: {'Accept': 'application/json'}),
          );
        } catch (_) {
          remaining.add(row);
        }
      }
      await _secure.write(key: 'push_cleanup', value: jsonEncode(remaining));
    } finally {
      dio.close();
    }
  }

  static String destination(String type) => switch (type) {
    'mood' => AppRouter.moodFeeling,
    'journal' => '/journal-compose',
    'streak' => '${AppRouter.home}?focus=streak',
    'affirmation' => AppRouter.dailyAffirmation,
    'quiz_share' => '/quiz-shared',
    _ => AppRouter.notifications,
  };

  Future<void> _receive(RemoteMessage message, {bool tapped = false}) async {
    final data = message.data;
    final owner = _local.activeUserId;
    if (owner == null ||
        data['user_id'] != owner ||
        DemoMode.instance.enabled) {
      return;
    }
    if (await TokenStorage().getToken() == null ||
        owner != _local.activeUserId) {
      return;
    }
    final id = data['notification_id'];
    if (id == null || id.isEmpty) return;
    final notification = AppNotification(
      id: id,
      title: message.notification?.title ?? 'Cozy Health',
      body: message.notification?.body ?? '',
      type: data['type'] ?? 'general',
      read: false,
      payload: {'user_id': owner},
      deepLink: destination(data['type'] ?? ''),
      createdAt: message.sentTime ?? DateTime.now(),
    );
    if (!_seen.add(id)) {
      if (tapped) open(notification);
      return;
    }
    await NotificationRepository().fetchNotifications();
    if (_local.activeUserId != owner) return;
    if (tapped) {
      open(notification);
    } else {
      _foreground.add(notification);
    }
  }

  void open(AppNotification notification) {
    _pendingTap = notification;
    _drainTap();
  }

  void _drainTap() async {
    final notification = _pendingTap;
    if (notification == null ||
        notification.payload?['user_id'] != _local.activeUserId) {
      return;
    }
    final owner = _local.activeUserId;
    if (await TokenStorage().getToken() == null ||
        owner != _local.activeUserId ||
        _pendingTap != notification) {
      return;
    }
    final path = AppRouter.router.routeInformationProvider.value.uri.path;
    if (AppRouter.navigatorKey.currentState == null ||
        const [
          '/',
          '/login',
          '/welcome',
          '/restore',
          '/onboarding',
          '/create-account',
          '/forgot-password',
          '/personalization',
          '/preparing-cozy',
        ].contains(path)) {
      return;
    }
    _pendingTap = null;
    AppRouter.router.push(destination(notification.type));
    if (notification.payload?['simulation'] != true) {
      unawaited(NotificationRepository().markAsRead(notification.id));
    }
  }

  void simulate(String category) {
    if (!internalBuild) return;
    final notification = AppNotification(
      id: const Uuid().v4(),
      title: 'Test $category reminder',
      body: 'Internal simulation: no push was sent.',
      type: category,
      read: false,
      payload: {'user_id': _local.activeUserId, 'simulation': true},
      createdAt: DateTime.now(),
    );
    _foreground.add(notification);
  }
}
