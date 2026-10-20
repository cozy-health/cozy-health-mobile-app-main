import 'package:flutter/material.dart';
import '../services/local_db_service.dart';
import '../services/usage_analytics.dart';

class AnalyticsOptIn extends StatefulWidget {
  const AnalyticsOptIn({super.key});
  @override
  State<AnalyticsOptIn> createState() => _AnalyticsOptInState();
}

class _AnalyticsOptInState extends State<AnalyticsOptIn> {
  bool _enabled = false, _busy = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = LocalDbService().activeUserId;
    try {
      final box = await LocalDbService().settingsBox();
      final preferences = box.get('privacy_preferences');
      if (mounted && owner == LocalDbService().activeUserId) {
        setState(
          () =>
              _enabled = preferences is Map && preferences['analytics'] == true,
        );
      }
    } catch (_) {
      /* Optional analytics remains off when storage is unavailable. */
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: _enabled,
    title: const Text('Help improve Cozy Health (optional)'),
    subtitle: const Text(
      'Share selected general usage events with PostHog. No health content, crisis activity or session recording. Change this in Privacy settings.',
    ),
    onChanged: _busy
        ? null
        : (value) async {
            setState(() => _busy = true);
            final owner = LocalDbService().activeUserId;
            try {
              final box = await LocalDbService().settingsBox();
              if (owner != LocalDbService().activeUserId) return;
              final previous = box.get('privacy_preferences');
              await box.put('privacy_preferences', {
                ...(previous is Map
                    ? Map<String, dynamic>.from(previous)
                    : <String, dynamic>{}),
                'analytics': value == true,
              });
              await UsageAnalytics.instance.preferenceChanged(value == true);
              if (mounted) setState(() => _enabled = value == true);
            } catch (_) {
              /* The optional choice remains off if storage fails. */
            } finally {
              if (mounted) setState(() => _busy = false);
            }
          },
  );
}
