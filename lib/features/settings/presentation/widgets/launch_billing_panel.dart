import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/services/legal_documents.dart';
import '../../data/native_billing_service.dart';
import '../screens/student_verification_screen.dart';

class LaunchBillingPanel extends StatefulWidget {
  const LaunchBillingPanel({super.key, this.showStudentVerification = true});
  final bool showStudentVerification;
  @override
  State<LaunchBillingPanel> createState() => _LaunchBillingPanelState();
}

class _LaunchBillingPanelState extends State<LaunchBillingPanel> {
  final _billing = NativeBillingService.instance;
  bool _loadFailed = false;
  bool _refreshing = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    if (_refreshing || _billing.busy) return;
    setState(() {
      _refreshing = true;
      _loadFailed = false;
    });
    try {
      await _billing.load();
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _billing,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Store purchases', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: context.cozyColors.wellness.small),
        if (!_billing.enabled)
          const Text(
            'Store purchases are currently unavailable. No purchase can be started here.',
          ),
        if (_billing.enabled && _billing.products.isEmpty)
          const Text(
            'No store prices are available. Try refreshing store options.',
          ),
        if (_billing.enabled)
          const Text(
            'Prices come from your store. Review the price and renewal details before confirming payment.',
          ),
        for (final product
            in _billing.enabled ? _billing.products : <ProductDetails>[])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: WellnessAction(
              key: ValueKey('purchase-${product.id}'),
              label: '${product.title} · ${product.price}',
              filled: true,
              onPressed: _billing.busy || _refreshing
                  ? null
                  : () => _billing.purchase(product),
            ),
          ),
        if (_billing.message != null)
          Text(_billing.message!, semanticsLabel: _billing.message),
        SizedBox(height: context.cozyColors.wellness.contentGap),
        WellnessAction(
          key: const ValueKey('refresh-store-options'),
          label: _refreshing
              ? 'Refreshing store options…'
              : 'Refresh store options',
          onPressed: _billing.busy || _refreshing ? null : _reload,
        ),
        if (_loadFailed)
          const Text('Could not refresh store options. Please try again.'),
        const SizedBox(height: 16),
        if (widget.showStudentVerification) const StudentPricingAction(),
        const SizedBox(height: 8),
        WellnessAction(
          key: const ValueKey('restore-store-purchases'),
          label: 'Restore purchases',
          filled: true,
          onPressed: _billing.busy || _refreshing ? null : _billing.restore,
        ),
        const SizedBox(height: 8),
        WellnessAction(
          key: const ValueKey('billing-terms'),
          label: 'Terms and renewal information',
          onPressed: () => LegalDocuments.open('https://cozyhealth.org/terms'),
        ),
      ],
    ),
  );
}

/// Shared Student entry point used beside the plan and on standalone restore.
class StudentPricingAction extends StatelessWidget {
  const StudentPricingAction({super.key});
  @override
  Widget build(BuildContext context) {
    final billing = NativeBillingService.instance;
    return ListenableBuilder(
      listenable: billing,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (billing.studentReverificationRequired)
            const Text(
              'Verify your school email again to continue Student purchase eligibility. Your store-confirmed paid access and successful renewals remain valid. Manage automatic renewal through Apple or Google.',
            ),
          if (billing.studentEligible)
            const Text(
              'Student pricing eligibility verified. A separate store purchase is required for paid access.',
            ),
          if (billing.studentEligible || billing.studentReverificationRequired)
            SizedBox(height: context.cozyColors.wellness.small),
          WellnessAction(
            key: const ValueKey('student-verification'),
            label: billing.studentReverificationRequired
                ? 'Verify school email again'
                : billing.studentEligible
                ? 'View Student eligibility'
                : 'Get student pricing',
            onPressed: billing.busy
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const StudentVerificationScreen(),
                      ),
                    );
                    if (!context.mounted) return;
                    try {
                      await billing.load();
                    } catch (_) {
                      if (context.mounted) {
                        AppSnackbar.show(
                          context,
                          const SnackBar(
                            content: Text(
                              'Could not refresh Student pricing. Refresh store options to try again.',
                            ),
                          ),
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    );
  }
}
