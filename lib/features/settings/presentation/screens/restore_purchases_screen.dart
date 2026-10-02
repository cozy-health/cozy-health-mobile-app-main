import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class RestorePurchasesScreen extends StatefulWidget {
  const RestorePurchasesScreen({super.key});

  @override
  State<RestorePurchasesScreen> createState() => _RestorePurchasesScreenState();
}

class _RestorePurchasesScreenState extends State<RestorePurchasesScreen> {
  String _status = 'idle'; // idle, checking, found, not_found

  Future<void> _restorePurchases() async {
    setState(() => _status = 'checking');

    // Mock network delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Randomly mock success or failure for testing purposes
    // In reality, this would depend on the store response
    setState(() {
      _status = 'found'; // Let's mock a success state by default
    });
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
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Restore Purchases',
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32),

              if (_status == 'idle' || _status == 'checking') ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.restore, size: 64, color: AppColors.primary),
                      SizedBox(height: 24),
                      Text(
                        'Missing your Pro access?',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'If you recently purchased a subscription or changed devices, you can restore your purchase here.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Make sure you are signed into the same App Store account used to make the original purchase.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 48),
                AppButton(
                  text: _status == 'checking'
                      ? 'Checking...'
                      : 'Restore Purchases',
                  onPressed: _status == 'checking' ? null : _restorePurchases,
                ),
              ] else if (_status == 'found') ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Purchase Restored',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Welcome back to Cozy Pro! Your subscription is now active on this device.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 48),
                AppButton(
                  text: 'Back to Settings',
                  onPressed: () => context.pop(),
                ),
              ] else if (_status == 'not_found') ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSubtleDark
                            : AppColors.textSubtleLight,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No Purchase Found',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 24,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'We couldn\'t find an active subscription for this App Store account.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'If you believe this is an error, please make sure you are signed into the correct App Store account or contact support.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                AppButton(
                  text: 'Try Again',
                  onPressed: () => setState(() => _status = 'idle'),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navigate to support
                    context.pop();
                  },
                  child: Text(
                    'Contact Support',
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
