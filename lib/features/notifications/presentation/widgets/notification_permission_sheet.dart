import 'package:flutter/material.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/services/push_notification_service.dart';

class NotificationPermissionSheet extends StatefulWidget {
  const NotificationPermissionSheet({super.key});
  static Future<void> show(BuildContext context) => showWellnessSheet<void>(
    context: context,
    builder: (_) => const NotificationPermissionSheet(),
  ).whenComplete(() => PushNotificationService.instance.decline());
  @override
  State<NotificationPermissionSheet> createState() =>
      _NotificationPermissionSheetState();
}

class _NotificationPermissionSheetState
    extends State<NotificationPermissionSheet> {
  bool journal = false, streak = false, affirmation = false, busy = false;
  String? _error;

  Future<void> _enable() async {
    if (busy) return;
    setState(() {
      busy = true;
      _error = null;
    });
    try {
      await PushNotificationService.instance.requestPermission(
        journal: journal,
        streak: streak,
        affirmation: affirmation,
      );
      await PushNotificationService.instance.decline();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not enable reminders. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return WellnessSheet(
      title: 'Can we send you gentle reminders?',
      busy: busy,
      children: [
        Icon(
          Icons.notifications_active_outlined,
          size: w.streakIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: w.contentGap),
        const Text(
          'A little encouragement, at your pace. Mood check-ins are included; choose any extras below.',
        ),
        SizedBox(height: w.gap),
        const WellnessSheetOption(
          key: ValueKey('reminder-mood'),
          label: 'Mood check-in',
          subtitle: 'Included when today’s check-in is missing.',
          icon: Icons.favorite_border,
          selected: true,
          onPressed: null,
        ),
        WellnessSheetOption(
          key: const ValueKey('reminder-journal'),
          label: 'Journal prompts',
          icon: Icons.auto_stories_outlined,
          selected: journal,
          onPressed: busy ? null : () => setState(() => journal = !journal),
        ),
        WellnessSheetOption(
          key: const ValueKey('reminder-streak'),
          label: 'Streak reminders',
          icon: Icons.local_fire_department_outlined,
          selected: streak,
          onPressed: busy ? null : () => setState(() => streak = !streak),
        ),
        WellnessSheetOption(
          key: const ValueKey('reminder-affirmation'),
          label: 'Affirmations',
          icon: Icons.auto_awesome_outlined,
          selected: affirmation,
          onPressed: busy
              ? null
              : () => setState(() => affirmation = !affirmation),
        ),
        SizedBox(height: w.small),
        const Text(
          'At most three reminders a day, at least two hours apart. Change times and quiet hours in Settings.',
        ),
        if (_error != null) Text(_error!, semanticsLabel: _error),
        SizedBox(height: w.gap),
        WellnessAction(
          key: const ValueKey('reminder-enable'),
          label: busy ? 'Enabling…' : 'Yes, remind me',
          filled: true,
          onPressed: busy ? null : _enable,
        ),
        SizedBox(height: w.small),
        WellnessAction(
          key: const ValueKey('reminder-decline'),
          label: 'Not now',
          onPressed: busy ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }
}
