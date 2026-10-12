import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/models/app_notification.dart';
import 'package:cozy_health/core/models/reminder_settings.dart';
import 'package:cozy_health/core/services/push_notification_service.dart';

class LegacyProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  int get typeId => 6;
  @override
  UserProfile read(BinaryReader reader) => throw UnimplementedError();
  @override
  void write(BinaryWriter writer, UserProfile p) {
    for (final value in [
      p.id,
      p.name,
      p.username ?? '',
      p.email,
      p.avatarUrl ?? '',
      p.bio ?? '',
      p.theme,
      p.accentColor,
      p.language,
    ]) {
      writer.writeString(value);
    }
    for (final value in [p.reduceMotion, p.highContrast, p.hapticsEnabled]) {
      writer.writeBool(value);
    }
    writer.writeDouble(p.textSize);
    for (final value in [
      p.showStats,
      p.showUsername,
      p.notificationsMaster,
      p.dailyCheckinEnabled,
    ]) {
      writer.writeBool(value);
    }
    writer.writeString(p.dailyCheckinTime);
    for (final value in [
      p.journalReminderEnabled,
      p.commentsNotifications,
      p.achievementsNotifications,
      p.marketingNotifications,
    ]) {
      writer.writeBool(value);
    }
    writer.writeInt(p.updatedAt.millisecondsSinceEpoch);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('soft prompt interval includes the full fourteen days', () {
    final now = DateTime.utc(2026, 10, 12);
    expect(PushNotificationService.shouldOfferPrompt(null, now), true);
    expect(
      PushNotificationService.shouldOfferPrompt(
        now.subtract(const Duration(days: 14)),
        now,
      ),
      true,
    );
    expect(
      PushNotificationService.shouldOfferPrompt(
        now.subtract(const Duration(days: 13, hours: 23)),
        now,
      ),
      false,
    );
    expect(
      PushNotificationService.shouldOfferPrompt(
        now.add(const Duration(days: 1)),
        now,
      ),
      false,
    );
  });

  test('only supported categories select destinations', () {
    expect(PushNotificationService.destination('mood'), '/mood-feeling');
    expect(PushNotificationService.destination('journal'), '/journal-compose');
    expect(PushNotificationService.destination('streak'), '/home?focus=streak');
    expect(
      PushNotificationService.destination('affirmation'),
      '/home?focus=affirmation',
    );
    expect(
      PushNotificationService.destination('https://example.com'),
      '/notifications',
    );
  });

  test(
    'old preference defaults never imply consent and extras remain optional',
    () {
      final profile = UserProfile.fromJson({
        'id': 'old',
        'daily_checkin_enabled': true,
      });
      expect(profile.pushConsent, false);
      final settings = ReminderSettings.resolve(profile.reminderSettings);
      expect(settings['streak_enabled'], false);
      expect(settings['affirmation_enabled'], false);
      expect(settings['quiet_start'], '22:00');
      expect(settings['quiet_end'], '08:00');
    },
  );

  test('legacy Hive profiles reopen without losing existing fields', () async {
    final directory = await Directory.systemTemp.createTemp('push_legacy_');
    Hive.init(directory.path);
    Hive.registerAdapter(LegacyProfileAdapter(), override: true);
    var box = await Hive.openBox<UserProfile>('legacy');
    await box.put(
      'old',
      UserProfile(
        id: 'old',
        name: 'Legacy',
        email: 'fixture@example.test',
        dailyCheckinTime: '20:30',
        updatedAt: DateTime.utc(2026),
      ),
    );
    await box.close();
    Hive.registerAdapter(UserProfileAdapter(), override: true);
    box = await Hive.openBox<UserProfile>('legacy');
    expect(box.get('old')!.name, 'Legacy');
    expect(box.get('old')!.dailyCheckinTime, '20:30');
    expect(box.get('old')!.pushConsent, false);
    expect(box.get('old')!.reminderSettings, isEmpty);
    await box.close();
    await directory.delete(recursive: true);
  });

  test(
    'consent schedules and notification routing survive Hive reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp('push_reopen_');
      Hive.init(directory.path);
      Hive.registerAdapter(UserProfileAdapter(), override: true);
      Hive.registerAdapter(AppNotificationAdapter(), override: true);
      var profiles = await Hive.openBox<UserProfile>('profiles');
      var notifications = await Hive.openBox<AppNotification>('notifications');
      final profile = UserProfile(
        id: 'p',
        name: 'Fixture',
        email: 'fixture@example.test',
        pushConsent: true,
        reminderSettings: {
          'quiet_start': '21:30',
          'mood_days': [1, 3],
        },
        updatedAt: DateTime.utc(2026),
      );
      await profiles.put('p', profile);
      await notifications.put(
        'n',
        AppNotification(
          id: 'n',
          title: 'Check in',
          body: 'A gentle reminder',
          type: 'mood',
          read: true,
          deepLink: '/mood-feeling',
          payload: {'user_id': '42'},
          readAt: DateTime.utc(2026),
          createdAt: DateTime.utc(2026),
        ),
      );
      await profiles.close();
      await notifications.close();
      profiles = await Hive.openBox<UserProfile>('profiles');
      notifications = await Hive.openBox<AppNotification>('notifications');
      expect(profiles.get('p')!.pushConsent, true);
      expect(profiles.get('p')!.reminderSettings['mood_days'], [1, 3]);
      expect(profiles.get('p')!.toJson()['push_consent'], true);
      expect(notifications.get('n')!.deepLink, '/mood-feeling');
      expect(notifications.get('n')!.payload, {'user_id': '42'});
      expect(notifications.get('n')!.readAt, DateTime.utc(2026));
      await profiles.close();
      await notifications.close();
      await directory.delete(recursive: true);
    },
  );
}
