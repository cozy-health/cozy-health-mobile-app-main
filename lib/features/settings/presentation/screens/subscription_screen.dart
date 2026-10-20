import '../widgets/launch_billing_panel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/routing/app_router.dart';
import 'package:go_router/go_router.dart';
import '../../data/subscription_repository.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
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
  @override
  void initState() {
    super.initState();
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
    final rows = (_catalog?['packages'] as List? ?? []).whereType<Map>();
    return Scaffold(
      appBar: AppBar(title: const Text('Plans and pricing')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Choose your pace',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Free, Student, and Premium. Prices depend on your confirmed billing country.',
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
          TextButton(
            onPressed: () => context.push(AppRouter.billingHistory),
            child: const Text('Billing history'),
          ),
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
    final free = row['tier'] == 'free';
    return Card(
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
            if (_yearly && !free)
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
              free
                  ? 'Basic tracking and journaling'
                  : 'Paid activation coming later',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
