import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/legal_documents.dart';
import '../../data/native_billing_service.dart';
import '../screens/student_verification_screen.dart';

class LaunchBillingPanel extends StatefulWidget {
  const LaunchBillingPanel({super.key});
  @override
  State<LaunchBillingPanel> createState() => _LaunchBillingPanelState();
}

class _LaunchBillingPanelState extends State<LaunchBillingPanel> {
  final _billing = NativeBillingService.instance;
  @override
  void initState() {
    super.initState();
    _billing.load().catchError((Object _) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _billing,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_billing.enabled)
          const Text(
            'Purchases will become available after Apple and Google store setup is complete.',
          ),
        for (final product in _billing.products)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AppButton(
              key: ValueKey('purchase-${product.id}'),
              text: '${product.title} · ${product.price}',
              onPressed: _billing.busy
                  ? null
                  : () => _billing.purchase(product),
            ),
          ),
        if (_billing.message != null)
          Text(_billing.message!, semanticsLabel: _billing.message),
        const SizedBox(height: 16),
        AppButton(
          key: const ValueKey('student-verification'),
          text: 'Apply for Student pricing',
          isOutlined: true,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const StudentVerificationScreen(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          key: const ValueKey('restore-store-purchases'),
          text: 'Restore purchases',
          isOutlined: true,
          onPressed: _billing.busy ? null : _billing.restore,
        ),
        const SizedBox(height: 8),
        AppButton(
          key: const ValueKey('billing-terms'),
          text: 'Terms and renewal information',
          isOutlined: true,
          onPressed: () => LegalDocuments.open('https://cozyhealth.org/terms'),
        ),
      ],
    ),
  );
}
