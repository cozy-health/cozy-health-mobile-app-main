import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/models/reminder_settings.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../notifications/presentation/widgets/notification_permission_sheet.dart';
import '../../data/profile_repository.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});
  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  final _repo = ProfileRepository();
  final _push = PushNotificationService.instance;
  bool _saving = false;

  Future<void> _change(UserProfile profile, String key, dynamic value) async {
    setState(() => _saving = true);
    try {
      await _repo.saveProfile(
        profile.copyWithField(key, value).copyWith(updatedAt: DateTime.now()),
      );
      await _push.refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save reminder settings. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setting(UserProfile profile, String key, dynamic value) =>
      _change(profile, 'reminder_settings', {
        ...ReminderSettings.resolve(profile.reminderSettings),
        key: value,
      });

  Future<void> _time(
    UserProfile profile,
    String key,
    String value, {
    bool mood = false,
  }) async {
    final parts = value.split(':');
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (chosen == null || !mounted) return;
    final time =
        '${chosen.hour.toString().padLeft(2, '0')}:${chosen.minute.toString().padLeft(2, '0')}';
    if (mood) {
      await _change(profile, 'daily_checkin_time', time);
    } else {
      await _setting(profile, key, time);
    }
  }

  Future<void> _days(
    UserProfile profile,
    String category,
    List<int> initial,
  ) async {
    final selected = initial.toSet();
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Reminder days'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 1; i <= 7; i++)
                  CheckboxListTile(
                    title: Text(
                      const [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ][i - 1],
                    ),
                    value: selected.contains(i),
                    onChanged: (value) => update(() {
                      if (value == true) {
                        selected.add(i);
                      } else {
                        selected.remove(i);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, selected.toList()..sort()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) {
      await _setting(profile, '${category}_days', result);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: StreamBuilder<UserProfile?>(
      stream: _repo.watchProfile(),
      initialData: LocalDbService().getUserProfile(),
      builder: (context, snapshot) {
        final p = snapshot.data;
        if (p == null) {
          return const Center(child: Text('Sign in to configure reminders.'));
        }
        final s = ReminderSettings.resolve(p.reminderSettings);
        final enabled = p.pushConsent && p.notificationsMaster;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Gentle reminders',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Up to three reminders per day, at least two hours apart. Quiet hours may move reminders later. A completed check-in cancels its reminder.',
            ),
            ListenableBuilder(
              listenable: _push,
              builder: (_, _) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_push.status),
                subtitle: Text('Phone permission: ${_push.permission}'),
                trailing: TextButton(
                  onPressed: openAppSettings,
                  child: const Text('Phone settings'),
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Allow reminders'),
              value: enabled,
              onChanged: _saving
                  ? null
                  : (value) async {
                      if (value && !p.pushConsent) {
                        await NotificationPermissionSheet.show(context);
                      } else {
                        await _change(p, 'notifications_master', value);
                      }
                    },
            ),
            if (p.pushConsent)
              TextButton(
                onPressed: _saving
                    ? null
                    : () => _change(p, 'push_consent', false),
                child: const Text('Withdraw reminder consent'),
              ),
            for (final c in ['mood', 'journal', 'streak', 'affirmation']) ...[
              const Divider(),
              SwitchListTile(
                title: Text(
                  const {
                    'mood': 'Mood check-in',
                    'journal': 'Journal prompt',
                    'streak': 'Streak reminder',
                    'affirmation': 'Affirmation',
                  }[c]!,
                ),
                subtitle: Text(
                  const {
                    'mood': 'Only when you have not checked in today.',
                    'journal': 'A writing prompt on your chosen days.',
                    'streak':
                        'Only while today’s check-in can continue your streak.',
                    'affirmation': 'Encouragement; no action required.',
                  }[c]!,
                ),
                value: switch (c) {
                  'mood' => p.dailyCheckinEnabled,
                  'journal' => p.journalReminderEnabled,
                  _ => s['${c}_enabled'] as bool,
                },
                onChanged: _saving || !enabled
                    ? null
                    : (v) {
                        if (c == 'mood') {
                          _change(p, 'daily_checkin_enabled', v);
                        } else if (c == 'journal') {
                          _change(p, 'journal_reminder_enabled', v);
                        } else {
                          _setting(p, '${c}_enabled', v);
                        }
                      },
              ),
              ListTile(
                title: const Text('Reminder time'),
                trailing: Text(
                  c == 'mood' ? p.dailyCheckinTime : s['${c}_time'] as String,
                ),
                onTap: _saving
                    ? null
                    : () => _time(
                        p,
                        '${c}_time',
                        c == 'mood'
                            ? p.dailyCheckinTime
                            : s['${c}_time'] as String,
                        mood: c == 'mood',
                      ),
              ),
              ListTile(
                title: const Text('Days'),
                trailing: Text(
                  (s['${c}_days'] as List)
                      .map(
                        (d) => const [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ][(d as int) - 1],
                      )
                      .join(', '),
                ),
                onTap: _saving
                    ? null
                    : () => _days(p, c, List<int>.from(s['${c}_days'] as List)),
              ),
            ],
            const Divider(),
            SwitchListTile(
              title: const Text('Quiet hours'),
              subtitle: const Text(
                'Delayed reminders are spaced out afterward. Streak reminders expire at midnight.',
              ),
              value: s['quiet_enabled'] as bool,
              onChanged: _saving
                  ? null
                  : (v) => _setting(p, 'quiet_enabled', v),
            ),
            for (final key in ['quiet_start', 'quiet_end'])
              ListTile(
                title: Text(
                  key == 'quiet_start'
                      ? 'Quiet hours start'
                      : 'Quiet hours end',
                ),
                trailing: Text(s[key] as String),
                onTap: _saving ? null : () => _time(p, key, s[key] as String),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Times use your saved account timezone. Equal start and end times mean no quiet interval.',
              ),
            ),
            if (PushNotificationService.internalBuild) ...[
              const Divider(),
              const Text('Internal notification testing'),
              const Text(
                'Simulations test banners and tap routing, not push delivery.',
              ),
              for (final c in ['mood', 'journal', 'streak', 'affirmation'])
                ListTile(
                  title: Text('Test $c'),
                  trailing: TextButton(
                    onPressed: () => _push.simulate(c, tap: true),
                    child: const Text('Open'),
                  ),
                  onTap: () => _push.simulate(c),
                ),
            ],
          ],
        );
      },
    ),
  );
}
