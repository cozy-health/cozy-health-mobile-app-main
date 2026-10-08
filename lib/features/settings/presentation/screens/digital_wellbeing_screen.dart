import 'package:flutter/material.dart';
import '../../../../core/models/digital_wellbeing_preferences.dart';
import '../../../../core/services/digital_wellbeing_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/friendly_error.dart';
import '../../../../core/widgets/skeleton_loader.dart';

class DigitalWellbeingScreen extends StatefulWidget {
  const DigitalWellbeingScreen({super.key, this.service});
  final DigitalWellbeingService? service;
  @override
  State<DigitalWellbeingScreen> createState() => _DigitalWellbeingScreenState();
}

class _DigitalWellbeingScreenState extends State<DigitalWellbeingScreen> {
  late final _service = widget.service ?? DigitalWellbeingService();
  DigitalWellbeingPreferences? _preferences;
  bool _saving = false;
  int _failures = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _service.load();
      if (mounted) {
        setState(() {
          _preferences = value;
          _failures = 0;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failures++);
    }
  }

  Future<void> _save(DigitalWellbeingPreferences value) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _service.save(value);
      if (mounted) setState(() => _preferences = value);
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't save your preferences. Please try again.",
            onRetry: () => _save(value),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Wellbeing')),
      body: preferences == null
          ? (_failures == 0
                ? const ListSkeleton(count: 3)
                : Padding(
                    padding: const EdgeInsets.all(24),
                    child: FriendlyError(
                      onRetry: _load,
                      failureCount: _failures,
                    ),
                  ))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Choose what feels comfortable. These preferences do not turn on reminders or enforce time limits yet.',
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Gentle reminders'),
                  value: preferences.gentleReminders,
                  onChanged: _saving
                      ? null
                      : (value) =>
                            _save(preferences.copyWith(gentleReminders: value)),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  initialValue: preferences.dailyLimitMinutes,
                  decoration: const InputDecoration(
                    labelText: 'Suggested daily usage limit',
                  ),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('1 hour')),
                    DropdownMenuItem(value: 0, child: Text('No limit')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) {
                          if (value != null) {
                            _save(
                              preferences.copyWith(dailyLimitMinutes: value),
                            );
                          }
                        },
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show usage summary at close'),
                  value: preferences.showUsageSummary,
                  onChanged: _saving
                      ? null
                      : (value) => _save(
                          preferences.copyWith(showUsageSummary: value),
                        ),
                ),
                if (_saving)
                  const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
    );
  }
}
