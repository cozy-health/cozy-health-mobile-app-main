import 'package:flutter/material.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../settings/data/settings_service.dart';

class ProviderShareConfirmDialog extends StatelessWidget {
  const ProviderShareConfirmDialog({
    super.key,
    this.providerName = 'your linked provider',
  });
  final String providerName;
  static Future<bool?> show(
    BuildContext context, {
    String providerName = 'your linked provider',
  }) => showDialog<bool>(
    context: context,
    builder: (_) => ProviderShareConfirmDialog(providerName: providerName),
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Share assessment results?'),
    content: SingleChildScrollView(
      child: Text(
        'Allow $providerName to see your assessment totals, severity labels and completion dates? This includes past and future results. Individual answers are not shared. You can turn sharing off in Settings.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Enable sharing'),
      ),
    ],
  );
}

/// Uses the existing category-level consent API; never sends answers to providers.
class QuizProviderSharing {
  static Future<void> share(
    BuildContext context, {
    SettingsService? service,
  }) async {
    final settings = service ?? SettingsService();
    try {
      final response = await settings.getProvider();
      final provider = response['provider'] as Map?;
      if (!context.mounted) return;
      if (response['has_provider'] != true ||
          provider == null ||
          provider['status'] != 'verified') {
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(
            content: const Text(
              'Link and verify a provider in Settings before sharing.',
            ),
          ),
        );
        return;
      }
      final linkId = provider['link_id'] ?? provider['id'];
      if (linkId == null) throw StateError('No provider link');
      final name =
          (provider['provider_name'] ?? provider['name']) as String? ??
          'your linked provider';
      if (await ProviderShareConfirmDialog.show(context, providerName: name) !=
          true) {
        return;
      }
      final flags = provider['consent_flags'] as Map? ?? {};
      if (flags['quizzes'] != true) {
        await settings.updateConsent(
          linkId: linkId.toString(),
          consentType: 'quizzes',
          value: true,
        );
      }
      await LocalDbService.instance.processSyncQueue(force: true);
      if (!context.mounted) return;
      final pending = LocalDbService.instance.pendingItems.any(
        (item) => item.type == 'quiz_attempt',
      );
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text(
            pending
                ? 'Sharing enabled. Saved results will appear when sync completes.'
                : 'Assessment results are available to your linked provider.',
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(
            content: const Text('Could not enable sharing. Please try again.'),
          ),
        );
      }
    }
  }
}
