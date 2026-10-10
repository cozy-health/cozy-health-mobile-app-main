import 'package:flutter/material.dart';
import '../models/sync_item.dart';
import '../services/local_db_service.dart';
import 'app_button.dart';

class SyncQueueBadge extends StatelessWidget {
  const SyncQueueBadge({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<List<SyncItem>>(
    stream: LocalDbService().watchPendingItems(),
    initialData: LocalDbService().pendingItems,
    builder: (context, snapshot) {
      final items = snapshot.data ?? [];
      if (items.isEmpty) return const SizedBox.shrink();
      return TextButton.icon(
        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
        label: Text('${items.length} pending'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
              ? AnimationStyle.noAnimation
              : null,
          isScrollControlled: true,
          builder: (_) => const _QueueSheet(),
        ),
      );
    },
  );
}

class _QueueSheet extends StatefulWidget {
  const _QueueSheet();
  @override
  State<_QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<_QueueSheet> {
  bool _retrying = false;
  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final result = await LocalDbService().processSyncQueue(force: true);
      if (mounted &&
          result.failed == 0 &&
          LocalDbService().pendingItems.isEmpty) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  static String _label(String type) =>
      const {
        'mood_entry': 'Mood check-in',
        'journal_entry': 'Journal entry',
        'user_profile': 'Profile',
        'user_preferences': 'Onboarding preferences',
        'safety_plan': 'Safety plan',
        'chat_message': 'Chat message',
        'chat_conversation': 'Conversation',
        'quiz_attempt': 'Assessment result',
        'saved_article': 'Saved article',
        'app_notification': 'Notification',
      }[type] ??
      'Saved change';
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<List<SyncItem>>(
        stream: LocalDbService().watchPendingItems(),
        initialData: LocalDbService().pendingItems,
        builder: (context, snapshot) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Waiting to sync',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: ListView(
                children: [
                  for (final item in snapshot.data ?? <SyncItem>[])
                    ListTile(
                      leading: const Icon(Icons.cloud_upload_outlined),
                      title: Text(_label(item.type)),
                      subtitle: Text(
                        _failureLabel(item.lastErrorCode) ??
                            (item.action == 'delete'
                                ? 'Removal pending'
                                : 'Saved on this device'),
                      ),
                    ),
                ],
              ),
            ),
            AppButton(
              text: 'Retry sync',
              isLoading: _retrying,
              onPressed: _retrying ? null : _retry,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );

  String? _failureLabel(String? code) => const {
    'session_expired': 'Log in again to upload this change.',
    'access_denied': 'This account cannot sync right now. Contact support.',
    'connection': 'Waiting for a connection.',
    'server': 'Sync is temporarily unavailable.',
    'secure_connection':
        'Secure connection unavailable. Check for an app update.',
    'invalid_payload': 'This change needs review before it can sync.',
    'ownership_conflict': 'This change could not be linked to your account.',
    'dependency_missing': 'Waiting for its related record to sync.',
    'database': 'The server could not save this change. Retry later.',
  }[code];
}
