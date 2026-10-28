import 'package:flutter/material.dart';
import 'cancel_subscription_screen.dart';

class BillingHistoryScreen extends StatelessWidget {
  const BillingHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const CancelSubscriptionScreen(
    title: 'Store purchase history',
    introduction:
        'Apple or Google provides your purchase receipts and tax details. Use the store account that paid for your Cozy subscription.',
  );
}
