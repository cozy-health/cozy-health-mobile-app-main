import '../widgets/launch_billing_panel.dart';
import '../widgets/store_plan_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../data/subscription_repository.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/models/subscription_status.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({
    super.key,
    this.title = 'Plans and pricing',
    this.deferBilling = false,
  });
  final String title;
  final bool deferBilling;
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Plan benefits are independent of country. Only native store product
  // metadata may supply checkout prices; legacy regional caches are ignored.
  static const _packages = [
    {
      'package_name': 'Standard',
      'features': [
        'Written journals',
        'Mood tracking and streaks',
        'Emergency support',
        'Limited community access',
      ],
    },
    {
      'package_name': 'Student',
      'features': [
        'All Premium features',
        'Requires verified current student enrolment',
      ],
    },
    {
      'package_name': 'Premium',
      'features': [
        'Written and voice journals',
        'Mood tracking and streaks',
        'Connect and chat with a provider',
        'Assessments',
        'Full community access',
        'Emergency support',
      ],
    },
  ];
  final _repo = SubscriptionRepository();
  final _owner = LocalDbService().activeUserId;
  late Future<SubscriptionStatus?> _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = _repo.fetchSubscription();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: AppPressable(
          label: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRouter.settings),
          child: SizedBox(
            width: context.cozyColors.wellness.touch,
            height: context.cozyColors.wellness.touch,
            child: const Icon(Icons.arrow_back),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          FutureBuilder<SubscriptionStatus?>(
            future: _subscription,
            builder: (context, snapshot) {
              final subscription = snapshot.data;
              if (_owner == LocalDbService().activeUserId &&
                  subscription != null &&
                  subscription.isStoreManaged) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: StorePlanPanel(
                    subscription: subscription,
                    onRefresh: () => setState(
                      () => _subscription = _repo.fetchSubscription(),
                    ),
                  ),
                );
              }
              if (_owner != LocalDbService().activeUserId ||
                  subscription == null ||
                  !subscription.isDevelopmentTest ||
                  !subscription.isActive) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WellnessPanel(
                  tinted: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Development test access',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${subscription.tier} · Ends ${subscription.expiresAt == null ? 'at the scheduled expiry' : DateFormat.yMMMd().add_jm().format(subscription.expiresAt!.toLocal())}',
                      ),
                      const Text(
                        'Temporary access for testing. No payment was collected.',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Text(
            'Choose your pace',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose Standard, Student, or Premium. Student includes all Premium features with verified current enrolment.',
          ),
          const SizedBox(height: 20),
          for (final row in _packages) _plan(row),
          if (widget.deferBilling)
            const Text(
              'Billing is on hold until Apple and Google store setup is complete. No purchase is available here.',
            )
          else
            const LaunchBillingPanel(),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'The store shows the applicable price and renewal details before payment. Student and Premium have the same paid benefits. Student purchases require verified current enrolment.',
              ),
            ),
          ),
          if (!widget.deferBilling)
            TextButton(
              onPressed: () => context.push(AppRouter.billingHistory),
              child: const Text('Billing history'),
            ),
          if (!widget.deferBilling)
            TextButton(
              onPressed: () => context.push(AppRouter.restorePurchases),
              child: const Text('Restore purchases'),
            ),
        ],
      ),
    );
  }

  Widget _plan(Map row) {
    return AppPressable(
      label: 'View ${row['package_name']} package',
      onPressed: () => showWellnessSheet<void>(
        context: context,
        builder: (context) => WellnessSheet(
          title: row['package_name']?.toString() ?? 'Package details',
          children: [
            if (row['description'] != null) Text(row['description'].toString()),

            for (final feature in row['features'] as List? ?? [])
              Text(feature.toString()),
            const Text(
              'Billing is on hold until Apple and Google store setup is complete.',
            ),
            const WellnessAction(label: 'Billing unavailable', onPressed: null),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row['package_name']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final feature in row['features'] as List? ?? [])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('✓ $feature'),
                ),
              Text(
                'Paid activation coming later',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
