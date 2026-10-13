import 'dart:async';
import 'package:flutter/material.dart';
import '../services/background_restore_service.dart';

class BackgroundRestoreBadge extends StatelessWidget {
  const BackgroundRestoreBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final service = BackgroundRestoreService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (_, _) => switch (service.state) {
        BackgroundRestoreState.restoring => const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Syncing your saved information…',
            style: TextStyle(fontSize: 12),
          ),
        ),
        BackgroundRestoreState.partial => TextButton.icon(
          onPressed: () => unawaited(service.retry()),
          icon: const Icon(Icons.sync, size: 16),
          label: Text(
            service.failedSections.isEmpty
                ? 'Saved information could not sync. Tap to retry'
                : '${service.failedSections.join(', ')} could not sync. Tap to retry',
          ),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
