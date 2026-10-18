import 'package:flutter/material.dart';

class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Billing history')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Billing records are not available in this app yet. No sample charges or receipts are shown.',
        ),
      ),
    ),
  );
}
