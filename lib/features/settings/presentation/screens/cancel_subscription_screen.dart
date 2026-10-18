import 'package:flutter/material.dart';

class CancelSubscriptionScreen extends StatelessWidget {
  const CancelSubscriptionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manage subscription')),
    body: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Subscription cancellation, pauses, and retention discounts are not available in this app yet. No change has been made to your subscription.',
        ),
      ),
    ),
  );
}
