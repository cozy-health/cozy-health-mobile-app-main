import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/settings_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SettingsService _settingsService = SettingsService();

  bool _loading = true;
  bool _processing = false;
  String? _error;

  Map<String, dynamic>? _subscription;
  List<dynamic> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      final subRes = await _settingsService.getSubscription();
      final packagesRes = await _settingsService.getPackages();

      setState(() {
        _subscription = subRes['subscription'] as Map<String, dynamic>?;
        _packages = packagesRes['packages'] as List<dynamic>? ?? [];
      });
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unable to load subscription.';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _activatePackage(int packageId) async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await _settingsService.activateSubscription(packageId: packageId);
      await _loadSubscriptionData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription activated successfully.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to activate subscription.');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _cancelSubscription() async {
    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await _settingsService.cancelSubscription();
      await _loadSubscriptionData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription cancelled successfully.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to cancel subscription.');
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _subscription?['status']?.toString() ?? 'inactive';
    final current = _subscription?['current'];
    final package = current is Map<String, dynamic> ? current['package'] : null;
    final packageName = package is Map<String, dynamic>
        ? package['package_name']?.toString() ?? 'Free Plan'
        : 'Free Plan';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      3.sh,
                      _header(context),
                      5.sh,

                      Text(
                        'My Subscription',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),

                      2.sh,

                      Text(
                        'Manage your plan, billing, and access to Cozy Health features.',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.grey,
                          height: 1.4,
                        ),
                      ),

                      3.sh,

                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _error!,
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                        3.sh,
                      ],

                      _currentPlanCard(
                        packageName: packageName,
                        status: status,
                        expiryDate: _subscription?['expiry_date']?.toString(),
                      ),

                      4.sh,

                      Text(
                        'Available Plans',
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      2.sh,

                      if (_packages.isEmpty)
                        Text(
                          'No packages available yet.',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.grey,
                          ),
                        )
                      else
                        ..._packages.map((item) {
                          final pkg = item as Map<String, dynamic>;
                          final id = int.tryParse(pkg['id'].toString()) ?? 0;
                          final name = pkg['package_name']?.toString() ?? 'Plan';
                          final price = pkg['price']?.toString() ?? '0';
                          final duration = pkg['duration']?.toString() ?? '';

                          return _packageCard(
                            id: id,
                            name: name,
                            price: price,
                            duration: duration,
                          );
                        }),

                      3.sh,

                      if (status == 'active')
                        Center(
                          child: TextButton(
                            onPressed: _processing ? null : _cancelSubscription,
                            child: Text(
                              _processing ? 'Processing...' : 'Cancel subscription',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      4.sh,
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            children: [
              const Icon(Icons.chevron_left, size: 22, color: AppColors.darkGrey),
              Text(
                'Back',
                style: AppTextStyles.body2.copyWith(color: AppColors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Subscription',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ),
        SizedBox(width: 14.w),
      ],
    );
  }

  Widget _currentPlanCard({
    required String packageName,
    required String status,
    String? expiryDate,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Plan', style: AppTextStyles.body2.copyWith(color: AppColors.grey)),
          1.sh,
          Text(
            packageName,
            style: AppTextStyles.heading1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          1.sh,
          Text(
            'Status: ${status.toUpperCase()}',
            style: AppTextStyles.body2.copyWith(
              color: status == 'active' ? AppColors.primary : AppColors.grey,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (expiryDate != null) ...[
            1.sh,
            Text(
              'Expires: $expiryDate',
              style: AppTextStyles.body2.copyWith(color: AppColors.darkGrey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _packageCard({
    required int id,
    required String name,
    required String price,
    required String duration,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4EA)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                0.8.sh,
                Text(
                  '₦$price ${duration.isNotEmpty ? '/ $duration' : ''}',
                  style: AppTextStyles.body2.copyWith(color: AppColors.grey),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: AppButton(
              text: _processing ? '...' : 'Activate',
              onPressed: _processing ? null : () => _activatePackage(id),
            ),
          ),
        ],
      ),
    );
  }
}