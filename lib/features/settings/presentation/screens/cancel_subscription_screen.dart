import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/models/subscription_status.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/subscription_repository.dart';
import '../widgets/store_plan_panel.dart';

class CancelSubscriptionScreen extends StatefulWidget {
  const CancelSubscriptionScreen({super.key});
  @override
  State<CancelSubscriptionScreen> createState() =>
      _CancelSubscriptionScreenState();
}

class _CancelSubscriptionScreenState extends State<CancelSubscriptionScreen> {
  final _repo = SubscriptionRepository();
  final _owner = LocalDbService().activeUserId;
  late Future<SubscriptionStatus?> _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = _repo.fetchSubscription();
  }

  void _refresh() => setState(() => _subscription = _repo.fetchSubscription());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Manage subscription'),
      leading: AppPressable(
        label: 'Back',
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(AppRouter.settings),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.arrow_back),
        ),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Manage renewal and cancellation in the store account used to purchase. Deleting your Cozy Health account does not cancel store billing.',
          ),
          const SizedBox(height: 24),
          FutureBuilder<SubscriptionStatus?>(
            future: _subscription,
            builder: (context, snapshot) {
              if (_owner != LocalDbService().activeUserId) {
                return const SizedBox.shrink();
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final subscription = snapshot.data;
              if (subscription != null && subscription.isStoreManaged) {
                return StorePlanPanel(
                  subscription: subscription,
                  onRefresh: _refresh,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No confirmed store subscription is available for this Cozy account. Connect to the internet and refresh to check.',
                  ),
                  const SizedBox(height: 16),
                  AppButton(text: 'Refresh plan status', onPressed: _refresh),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
