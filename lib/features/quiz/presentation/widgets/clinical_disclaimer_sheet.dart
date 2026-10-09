import 'package:flutter/material.dart';
import '../../../../core/services/local_db_service.dart';

class ClinicalDisclaimerSheet extends StatelessWidget {
  const ClinicalDisclaimerSheet({super.key});
  static const acknowledgementKey = 'clinical_quiz_disclaimer_v1';
  static Future<bool?> show(BuildContext context) async {
    final settings = await LocalDbService.instance.settingsBox();
    if (settings.get(acknowledgementKey) == true) return true;
    if (!context.mounted) return false;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ClinicalDisclaimerSheet(),
    );
    if (accepted == true) await settings.put(acknowledgementKey, true);
    return accepted;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.info_outline, size: 48),
          const SizedBox(height: 20),
          Text(
            'Before we start',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'This is not a diagnosis. Talk to a professional for clinical evaluation.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('I understand'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}
