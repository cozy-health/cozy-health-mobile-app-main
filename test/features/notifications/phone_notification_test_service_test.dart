import 'dart:async';
import 'dart:convert';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/services/phone_notification_test_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  final date = DateTime.fromMillisecondsSinceEpoch(
    (DateTime.now().millisecondsSinceEpoch ~/ 1000) * 1000 + 60000,
    isUtc: true,
  );
  late List<MethodCall> calls;
  late List<AppNotification> opened;
  String? owner;
  var permission = true;
  Map<String, dynamic>? launch;
  PhoneNotificationTestService service({bool enabled = true}) =>
      PhoneNotificationTestService(
        enabled: enabled,
        currentOwner: () => owner,
        allowed: () async => permission,
        now: () => date,
        onOpen: opened.add,
      );
  String payload({
    String user = '1',
    String category = 'mood',
    DateTime? created,
  }) => jsonEncode({
    'kind': 'cozy_phone_test',
    'user_id': user,
    'category': category,
    'created_at': (created ?? date).toIso8601String(),
  });
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    FlutterLocalNotificationsPlatform.instance =
        IOSFlutterLocalNotificationsPlugin();
    calls = [];
    opened = [];
    owner = '1';
    permission = true;
    launch = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'getNotificationAppLaunchDetails') return launch;
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'phone test schedules OS delivery with sound and does not open a route',
    () async {
      final test = service();
      expect(await test.schedule('mood'), contains('Lock your phone'));
      final scheduled = calls.singleWhere(
        (call) => call.method == 'zonedSchedule',
      );
      final args = scheduled.arguments as Map;
      expect(args['id'], 970180);
      expect(
        DateTime.parse(
          '${args['scheduledDateTime']}Z',
        ).toUtc().difference(date).inSeconds,
        10,
      );
      expect(
        (args['platformSpecifics'] as Map)['sound'],
        'cozy_notification.wav',
      );
      expect((args['platformSpecifics'] as Map)['presentList'], true);
      expect(args['timeZoneName'], 'Etc/UTC');
      expect(jsonDecode(args['payload'] as String)['user_id'], '1');
      expect(opened, isEmpty);
      final init =
          calls.singleWhere((call) => call.method == 'initialize').arguments
              as Map;
      expect(init['requestAlertPermission'], false);
      expect(init['requestSoundPermission'], false);
    },
  );
  test('permission denial and production builds never schedule', () async {
    permission = false;
    expect(await service().schedule('mood'), contains('Enable phone alerts'));
    await service(enabled: false).schedule('mood');
    expect(calls, isEmpty);
  });
  test('affirmation is readable in the phone notification itself', () async {
    final test = PhoneNotificationTestService(
      enabled: true,
      currentOwner: () => owner,
      allowed: () async => true,
      now: () => date,
      onOpen: opened.add,
      affirmation: () async => 'You deserve kindness, including from yourself.',
    );
    await test.schedule('affirmation');
    final args =
        calls.singleWhere((call) => call.method == 'zonedSchedule').arguments
            as Map;
    expect(args['title'], 'Your Cozy affirmation');
    expect(args['body'], 'You deserve kindness, including from yourself.');
    expect(opened, isEmpty);
  });
  test('offline affirmation uses readable fallback copy', () async {
    await service().schedule('affirmation');
    final args =
        calls.singleWhere((call) => call.method == 'zonedSchedule').arguments
            as Map;
    expect(args['body'], PhoneNotificationTestService.fallbackAffirmation);
    expect(args['body'], isNot(contains('Tap to open')));
  });
  test('valid taps open only the current account supported category', () {
    final test = service();
    test.handleTap(payload());
    expect(opened.single.type, 'mood');
    expect(opened.single.payload?['simulation'], true);
    test.handleTap(payload(user: 'other'));
    test.handleTap(payload(category: 'unknown'));
    test.handleTap(payload(created: date.subtract(const Duration(hours: 2))));
    test.handleTap('bad json');
    owner = null;
    test.handleTap(payload());
    expect(opened, hasLength(1));
  });
  test('cold-start tap is recovered during initialization', () async {
    launch = {
      'notificationLaunchedApp': true,
      'notificationResponse': {
        'notificationResponseType': 0,
        'payload': payload(category: 'journal'),
      },
    };
    await service().initialize();
    expect(opened.single.type, 'journal');
  });
  test('logout cancels all four test IDs', () async {
    final test = service();
    await test.initialize();
    await test.cancel();
    expect(
      calls
          .where((call) => call.method == 'cancel')
          .map((call) => call.arguments),
      [970180, 970181, 970182, 970183],
    );
  });
  test('account change while checking permission does not schedule', () async {
    final waiting = Completer<bool>();
    final test = PhoneNotificationTestService(
      enabled: true,
      currentOwner: () => owner,
      allowed: () => waiting.future,
      now: () => date,
      onOpen: opened.add,
    );
    final work = test.schedule('mood');
    owner = '2';
    waiting.complete(true);
    expect(await work, contains('Account changed'));
    expect(calls.where((call) => call.method == 'zonedSchedule'), isEmpty);
  });
}
