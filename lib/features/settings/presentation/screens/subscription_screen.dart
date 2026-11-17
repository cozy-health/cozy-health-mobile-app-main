import '../widgets/launch_billing_panel.dart';
import '../widgets/store_plan_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../data/subscription_repository.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../data/native_billing_service.dart';
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
  static const List<Map<String, Object>> _packages = [
    {
      'package_name': 'Standard',
      'features': [
        'Written journals',
        'Mood tracking and streaks',
        'Emergency support',
        'Read-only community access',
      ],
    },
    {
      'package_name': 'Student',
      'features': ['All Premium features', 'Verify a Nigerian academic email'],
    },
    {
      'package_name': 'Premium',
      'features': [
        'Written and voice journals',
        'Mood tracking and streaks',
        'Connect and chat with a provider',
        'Assessments and challenges',
        'Trends and insights dashboard',
        'Explicit journal sharing with your provider',
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
        padding: EdgeInsets.all(context.cozyColors.wellness.page),
        children: [
          FutureBuilder<SubscriptionStatus?>(
            future: _subscription,
            builder: (context, snapshot) {
              final subscription = snapshot.data;
              if (snapshot.hasError) {
                return WellnessPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Your current plan could not be loaded. Refresh to check your access.',
                      ),
                      WellnessAction(
                        key: const ValueKey('retry-current-plan'),
                        label: 'Refresh plan status',
                        onPressed: () => setState(
                          () => _subscription = _repo.fetchSubscription(),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Checking your current plan…');
              }
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
            'Choose Standard, Student, or Premium. Student includes all Premium features with verified Nigerian academic email eligibility.',
          ),
          const SizedBox(height: 20),
          for (final row in _packages) _plan(row),
          if (widget.deferBilling)
            const Text(
              'Store purchases are currently unavailable. No purchase can be started here.',
            )
          else
            const WellnessPanel(
              child: LaunchBillingPanel(showStudentVerification: false),
            ),
          const SizedBox(height: 20),
          const WellnessPanel(
            child: Text(
              'The store shows the applicable price and renewal details before payment. Student and Premium have the same paid benefits. Verify a Nigerian academic email ending in .edu.ng or an approved school domain. Eligibility lasts 12 months and does not activate a subscription.',
            ),
          ),
          if (!widget.deferBilling)
            TextButton(
              onPressed: () => context.push(AppRouter.billingHistory),
              child: const Text('Billing history'),
            ),
        ],
      ),
    );
  }

  Widget _plan(Map<String, Object> row) {
    final w = context.cozyColors.wellness;
    final name = row['package_name'] as String;
    final features = row['features'] as List<String>;
    final student = name == 'Student';
    return Padding(
      padding: EdgeInsets.only(bottom: w.gap),
      child: WellnessPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: w.small),
            FutureBuilder<SubscriptionStatus?>(
              future: _subscription,
              builder: (context, snapshot) {
                final current = snapshot.data;
                return _owner == LocalDbService().activeUserId &&
                        current != null &&
                        current.isActive &&
                        current.tier.toLowerCase() == name.toLowerCase()
                    ? const Text('Current plan')
                    : const SizedBox.shrink();
              },
            ),
            Text(
              student
                  ? 'Premium benefits with verified academic email eligibility.'
                  : name == 'Premium'
                  ? 'More ways to reflect, connect and understand your wellbeing.'
                  : 'Everyday tools for your wellbeing.',
            ),
            SizedBox(height: w.contentGap),
            for (final feature in features)
              Padding(
                padding: EdgeInsets.only(bottom: w.small),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: w.actionIcon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: w.small),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            if (student && !widget.deferBilling) ...[
              SizedBox(height: w.small),
              const StudentPricingAction(),
            ],
            SizedBox(height: w.contentGap),
            WellnessAction(
              key: ValueKey('plan-details-${name.toLowerCase()}'),
              label: 'View $name details',
              onPressed: () => showWellnessSheet<void>(
                context: context,
                builder: (context) => ListenableBuilder(
                  listenable: NativeBillingService.instance,
                  builder: (context, _) => WellnessSheet(
                    title: name,
                    children: [
                      for (final feature in features)
                        Padding(
                          padding: EdgeInsets.only(bottom: w.small),
                          child: Text(feature),
                        ),
                      SizedBox(height: w.contentGap),
                      Text(
                        widget.deferBilling ||
                                !NativeBillingService.instance.enabled
                            ? 'Store purchases are currently unavailable. No purchase can be started here.'
                            : 'Available prices and purchase options are shown in Store purchases on the plans page. Your store confirms the price and renewal details before payment.',
                      ),
                      if (student)
                        const Text(
                          'Student eligibility lasts 12 months. Verification enables Student pricing; it does not activate paid access.',
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
