import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/widgets/app_snackbar.dart';

class NotificationDeniedSheet extends StatelessWidget {
  const NotificationDeniedSheet({super.key});

  static Future<void> show(BuildContext context) => showWellnessSheet<void>(
    context: context,
    builder: (_) => const NotificationDeniedSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return WellnessSheet(
      title: 'Notifications are turned off.',
      children: [
        Icon(
          Icons.notifications_off_outlined,
          size: w.streakIcon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(height: w.gap),
        const Text(
          'To receive reminders, turn them on in your device settings. You can change your reminder choices in Cozy at any time.',
        ),
        SizedBox(height: w.section),
        WellnessAction(
          key: const ValueKey('notification-open-settings'),
          label: 'Open Settings',
          filled: true,
          onPressed: () async {
            final opened = await openAppSettings();
            if (!context.mounted) return;
            if (opened) {
              Navigator.pop(context, true);
            } else {
              AppSnackbar.show(
                context,
                const SnackBar(
                  content: Text(
                    'Could not open Settings. Open your phone settings and choose Cozy notifications.',
                  ),
                ),
              );
            }
          },
        ),
        SizedBox(height: w.small),
        WellnessAction(
          key: const ValueKey('notification-later'),
          label: 'Maybe later',
          onPressed: () => Navigator.pop(context, false),
        ),
      ],
    );
  }
}
