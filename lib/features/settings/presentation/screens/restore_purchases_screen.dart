import 'package:flutter/material.dart';

class RestorePurchasesScreen extends StatelessWidget {
  const RestorePurchasesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Restore purchases')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Purchase restore is not available yet. No store check has been performed and no subscription has been activated.',
        ),
      ),
    ),
  );
}
