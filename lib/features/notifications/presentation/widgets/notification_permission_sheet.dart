import 'package:flutter/material.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/services/push_notification_service.dart';

class NotificationPermissionSheet extends StatefulWidget {
  const NotificationPermissionSheet({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    sheetAnimationStyle: shouldReduceMotion(context)
        ? AnimationStyle.noAnimation
        : null,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const NotificationPermissionSheet(),
  ).whenComplete(() => PushNotificationService.instance.decline());
  @override
  State<NotificationPermissionSheet> createState() =>
      _NotificationPermissionSheetState();
}

class _NotificationPermissionSheetState
    extends State<NotificationPermissionSheet> {
  bool journal = false, streak = false, affirmation = false, busy = false;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                Theme.of(context).colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.spa_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.notifications_active_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Can we send you gentle reminders?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enable mood check-in reminders and choose extras below. At most three reminders a day, two hours apart. You control times and quiet hours in Settings.',
          ),
          const ListTile(
            leading: Icon(Icons.favorite_border),
            title: Text('Mood check-in'),
            subtitle: Text('A reminder when today’s check-in is missing.'),
            trailing: Icon(Icons.check),
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.auto_stories_outlined),
            title: const Text('Journal prompts'),
            value: journal,
            onChanged: busy ? null : (v) => setState(() => journal = v!),
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: const Text('Streak reminders'),
            value: streak,
            onChanged: busy ? null : (v) => setState(() => streak = v!),
          ),
          CheckboxListTile(
            secondary: const Icon(Icons.favorite_border),
            title: const Text('Affirmations'),
            value: affirmation,
            onChanged: busy ? null : (v) => setState(() => affirmation = v!),
          ),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    await PushNotificationService.instance.requestPermission(
                      journal: journal,
                      streak: streak,
                      affirmation: affirmation,
                    );
                    await PushNotificationService.instance.decline();
                    if (context.mounted) Navigator.pop(context);
                  },
            child: Text(busy ? 'Enabling…' : 'Yes, remind me'),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    await PushNotificationService.instance.decline();
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Not now'),
          ),
        ],
      ),
    ),
  );
}
