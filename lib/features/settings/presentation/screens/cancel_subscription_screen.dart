import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/subscription_repository.dart';

class CancelSubscriptionScreen extends StatefulWidget {
  const CancelSubscriptionScreen({super.key});

  @override
  State<CancelSubscriptionScreen> createState() =>
      _CancelSubscriptionScreenState();
}

class _CancelSubscriptionScreenState extends State<CancelSubscriptionScreen> {
  String? _selectedReason;
  bool _showRetention = false;

  final List<Map<String, String>> _reasons = [
    {
      'id': 'expensive',
      'title': 'Too expensive',
      'retention_title': 'How about 50% off your next month?',
      'retention_desc':
          'We want to make Cozy accessible. Stay with us for half the price next month while you decide.',
      'retention_action': 'Claim 50% Off',
    },
    {
      'id': 'not_using',
      'title': 'Not using it enough',
      'retention_title': 'Need a break? Pause instead.',
      'retention_desc':
          'You can pause your subscription for 1, 2, or 3 months without losing any of your data or Pro features.',
      'retention_action': 'Pause Subscription',
    },
    {
      'id': 'missing_feature',
      'title': 'Missing a feature I need',
      'retention_title': 'Tell us what you need',
      'retention_desc':
          'We are constantly building new features based on feedback. Let us know what is missing and we might just build it.',
      'retention_action': 'Share Feedback',
    },
    {
      'id': 'other',
      'title': 'Other reason',
      'retention_title': '',
      'retention_desc': '',
      'retention_action': '',
    },
  ];

  Map<String, String>? get _currentRetention {
    if (_selectedReason == null || _selectedReason == 'other') return null;
    return _reasons.firstWhere((r) => r['id'] == _selectedReason);
  }

  void _onReasonSelected(String id) {
    setState(() {
      _selectedReason = id;
      _showRetention = id != 'other';
    });
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cancel Subscription?',
            style: AppTextStyles.heading2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Your Pro access will continue until the end of your billing period (Oct 24, 2026).',
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Pro',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                await SubscriptionRepository().cancel();
                if (mounted && context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to subscription
                  AppSnackbar.show(
                    context,
                    AppSnackbar.fromLegacy(
                      content: Text(
                        'Subscription cancelled. We will miss you!',
                      ),
                    ),
                  );
                }
              },
              child: Text(
                'Confirm Cancel',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Close',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              Text(
                'We\'ll miss you',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Before you go, could you let us know why you\'re cancelling? This helps us improve Cozy for everyone.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: _reasons.map((reason) {
                    final isSelected = _selectedReason == reason['id'];
                    final isLast = reason == _reasons.last;
                    return Column(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onReasonSelected(reason['id']!),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : AppColors.textSubtle,
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      reason['title']!,
                                      style: AppTextStyles.body1.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: isSelected
                                            ? FontWeight.w500
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              if (_showRetention && _currentRetention != null) ...[
                SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _currentRetention!['retention_title']!,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _currentRetention!['retention_desc']!,
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      SizedBox(height: 24),
                      AppButton(
                        text: _currentRetention!['retention_action']!,
                        onPressed: () {
                          context.pop();
                          AppSnackbar.show(
                            context,
                            AppSnackbar.fromLegacy(
                              content: Text('Offer applied successfully!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 48),
              if (_selectedReason != null) ...[
                AppButton(
                  text: 'Keep Subscription',
                  onPressed: () => context.pop(),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _confirmCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue to cancel',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
