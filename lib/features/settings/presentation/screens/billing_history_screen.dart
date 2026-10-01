import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class BillingHistoryScreen extends StatefulWidget {
  const BillingHistoryScreen({super.key});

  @override
  State<BillingHistoryScreen> createState() => _BillingHistoryScreenState();
}

class _BillingHistoryScreenState extends State<BillingHistoryScreen> {
  // Mock data
  final List<Map<String, dynamic>> _history = [
    {
      'date': 'Sep 24, 2026',
      'plan': 'Cozy Pro - Monthly',
      'amount': '\$7.99',
    },
    {
      'date': 'Aug 24, 2026',
      'plan': 'Cozy Pro - Monthly',
      'amount': '\$7.99',
    },
    {
      'date': 'Jul 24, 2026',
      'plan': 'Cozy Pro - Monthly',
      'amount': '\$7.99',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Billing History',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: _history.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                itemCount: _history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _history[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warmBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long, color: AppColors.textSubtle, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['plan'] as String,
                                      style: AppTextStyles.body1.copyWith(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item['amount'] as String,
                                    style: AppTextStyles.body1.copyWith(
                                      color: AppColors.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['date'] as String,
                                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Downloading receipt...')),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.download, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Download Receipt',
                                      style: AppTextStyles.body2.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textSubtle),
            const SizedBox(height: 24),
            Text(
              'No Billing History',
              style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Text(
              'You have not made any payments yet. Subscribe to Pro to see your receipts here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
