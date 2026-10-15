import 'package:flutter/material.dart';

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
    scrollable: true,
    title: const Text('Share this assessment result?'),
    content: SingleChildScrollView(
      child: Text(
        'Allow $providerName to view this selected result’s total, interpretation, date and recommendations? This enables quiz consent, but future results remain private until you share them. Individual answers are not shared. You can revoke access.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(true),
        child: const Text('Share this result'),
      ),
    ],
  );
}
