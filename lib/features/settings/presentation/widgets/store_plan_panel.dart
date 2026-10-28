import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/subscription_status.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../data/store_subscription_links.dart';

class StorePlanPanel extends StatelessWidget {
  const StorePlanPanel({
    super.key,
    required this.subscription,
    required this.onRefresh,
    this.openLink = StoreSubscriptionLinks.open,
  });

  final SubscriptionStatus subscription;
  final VoidCallback onRefresh;
  final Future<bool> Function(Uri) openLink;

  Future<void> _open(BuildContext context, Uri? uri) async {
    final opened = uri != null && await openLink(uri);
    if (!opened && context.mounted) {
      await showWellnessDialog<void>(
        context: context,
        builder: (_) => const WellnessSheet(
          title: 'Could not open the store',
          children: [
            Text(
              'Please try again. You can also manage subscriptions and purchase history in the store account used to purchase.',
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!subscription.isStoreManaged) return const SizedBox.shrink();
    final state = subscription.isActive
        ? subscription.storeState ?? 'active'
        : const [
            'on_hold',
            'paused',
            'revoked',
            'billing_retry',
            'pending',
            'unknown',
          ].contains(subscription.storeState)
        ? subscription.storeState!
        : 'expired';
    final status = switch (state) {
      'trial' => 'Trial active',
      'canceled' => 'Automatic renewal off',
      'grace_period' => 'Payment needs attention — temporary grace period',
      'billing_retry' || 'on_hold' => 'Payment needs attention',
      'paused' => 'Paused',
      'revoked' => 'Store access removed',
      'pending' => 'Waiting for store confirmation',
      'unknown' => 'Store status could not be confirmed',
      'expired' => 'Ended',
      _ => 'Active',
    };
    final dateLabel = state == 'grace_period'
        ? 'Grace period ends'
        : state == 'expired'
        ? 'Ended'
        : subscription.isActive &&
              subscription.autoRenews == true &&
              const ['active', 'trial'].contains(state)
        ? 'Scheduled renewal'
        : const [
            'revoked',
            'on_hold',
            'paused',
            'billing_retry',
            'pending',
            'unknown',
          ].contains(state)
        ? 'Store-recorded period end'
        : 'Confirmed period end';
    return WellnessPanel(
      tinted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your ${subscription.tier} plan',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(status),
          Text('Managed through ${subscription.storeName}'),
          if (subscription.expiresAt != null)
            Text(
              '$dateLabel: ${DateFormat.yMMMd().add_jm().format(subscription.expiresAt!.toLocal())}',
            ),
          const SizedBox(height: 12),
          const Text(
            'Your store provides payment receipts and tax details. Deleting your Cozy account does not cancel store billing.',
          ),
          const SizedBox(height: 16),
          AppButton(
            text: 'Manage subscription',
            isOutlined: true,
            onPressed: () => _open(
              context,
              StoreSubscriptionLinks.manage(subscription.storePlatform),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            text: 'View store purchase history',
            isOutlined: true,
            onPressed: () => _open(
              context,
              StoreSubscriptionLinks.history(subscription.storePlatform),
            ),
          ),
          const SizedBox(height: 8),
          AppButton(
            text: 'Refresh plan status',
            isOutlined: true,
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
