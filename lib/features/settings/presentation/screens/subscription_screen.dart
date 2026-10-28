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
  final _repo = SubscriptionRepository();
  final _country = TextEditingController();
  Map<String, dynamic>? _catalog;
  bool _yearly = false, _loading = true;
  String? _error;
  int _generation = 0;
  final _owner = LocalDbService().activeUserId;
  late Future<SubscriptionStatus?> _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = _repo.fetchSubscription();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await LocalDbService().settingsBox();
    if (!mounted) return;
    _country.text =
        settings.get('billing_country') as String? ??
        WidgetsBinding.instance.platformDispatcher.locale.countryCode ??
        '';
    if (_country.text.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    await _load();
  }

  Future<void> _load() async {
    final country = _country.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(country)) {
      setState(() {
        _error = 'Enter a two-letter billing country code, such as NG.';
        _loading = false;
      });
      return;
    }
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _catalog = null;
    });
    try {
      final data = await _repo.fetchPrices(country);
      if (!mounted || generation != _generation) return;
      setState(() {
        _catalog = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _error =
              'Could not load regional prices. Check your connection and retry.';
        });
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _country.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_catalog?['packages'] as List? ?? []).whereType<Map>().where(
      (row) => const ['standard', 'student', 'premium'].contains(row['tier']),
    );
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
            'Standard, Student, and Premium. Student includes all Premium features. Prices depend on your confirmed billing country.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _country,
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Billing country code',
              helperText: 'For example NG for Nigeria or GB for United Kingdom',
            ),
          ),
          FilledButton(
            onPressed: _loading ? null : _load,
            child: const Text('Confirm country and load prices'),
          ),
          SwitchListTile(
            title: const Text('Pay yearly'),
            subtitle: const Text('See the full annual charge and savings'),
            value: _yearly,
            onChanged: (value) => setState(() => _yearly = value),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!),
          if (!_loading && _error == null && _catalog != null && rows.isEmpty)
            const Text(
              'Pricing is not available for this country yet. No other region’s prices have been substituted.',
            ),
          for (final row in rows) _plan(row),
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
    final currency = row['currency']?.toString() ?? '';
    final digits = (row['currency_decimals'] as num?)?.toInt() ?? 2;
    final format = NumberFormat.currency(
      name: currency,
      symbol: '$currency ',
      decimalDigits: digits,
    );
    final monthly = num.tryParse('${row['price']}') ?? 0;
    final annual = num.tryParse('${row['yearly_price']}') ?? 0;
    return AppPressable(
      label: 'View ${row['package_name']} package',
      onPressed: () => showWellnessSheet<void>(
        context: context,
        builder: (context) => WellnessSheet(
          title: row['package_name']?.toString() ?? 'Package details',
          children: [
            if (row['description'] != null) Text(row['description'].toString()),
            Text(
              '${format.format(_yearly ? annual : monthly)}/${_yearly ? 'year' : 'month'}',
            ),
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
              const SizedBox(height: 10),
              Text(
                '${format.format(_yearly ? annual : monthly)}/${_yearly ? 'year' : 'month'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (_yearly)
                Text(
                  '${format.format(annual / 12)} equivalent per month · ${row['annual_discount']}% annual saving',
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
