import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/models/subscription_status.dart';
import '../../data/subscription_repository.dart';
import 'package:intl/intl.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Subscription',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
        actions: [
          // Temp toggle for development removed, using stream
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<SubscriptionStatus?>(
          stream: SubscriptionRepository().watchStatus(),
          builder: (context, snapshot) {
            final status = snapshot.data;
            final isPro = status?.isActive == true && status?.cancelAtPeriodEnd == false;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  isPro ? _buildProState(status!) : _buildFreeState(),
                  const SizedBox(height: 48),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildFreeState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Current Plan',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.favorite_border, color: AppColors.text, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cozy Free',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Basic journaling and mood tracking',
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cozy Pro',
                      style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Popular',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$7.99',
                    style: AppTextStyles.heading1.copyWith(fontSize: 36, color: AppColors.text),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '/month',
                      style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildFeatureRow('Unlimited AI therapy conversations'),
              const SizedBox(height: 12),
              _buildFeatureRow('Detailed mood analytics and trends'),
              const SizedBox(height: 12),
              _buildFeatureRow('Priority customer support'),
              const SizedBox(height: 12),
              _buildFeatureRow('Data export and backup'),
              const SizedBox(height: 32),
              AppButton(
                text: 'Start Free Trial',
                onPressed: () async {
                  await SubscriptionRepository().purchase('pro');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Welcome to Cozy Pro!')),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                '7 days free, then \$7.99/month. Cancel anytime.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProState(SubscriptionStatus status) {
    final renewText = status.expiresAt != null 
        ? 'Renews on ${DateFormat('MMM d, yyyy').format(status.expiresAt!)}' 
        : 'Active Subscription';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Current Plan',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cozy Pro',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      renewText,
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.autorenew,
                label: 'Change Plan',
                onTap: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _SettingsRow(
                icon: Icons.receipt_long_outlined,
                label: 'Billing History',
                onTap: () => context.push(AppRouter.billingHistory),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _SettingsRow(
                icon: Icons.restore,
                label: 'Restore Purchases',
                onTap: () => context.push(AppRouter.restorePurchases),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _SettingsRow(
                icon: Icons.cancel_outlined,
                label: 'Cancel Subscription',
                isDanger: true,
                onTap: () => context.push(AppRouter.cancelSubscription),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body1.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}