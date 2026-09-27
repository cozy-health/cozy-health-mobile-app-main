import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/settings_service.dart';

class ProviderScreen extends StatefulWidget {
  const ProviderScreen({super.key});

  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen> {
  final SettingsService _settingsService = SettingsService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  bool _verifying = false;
  bool _removing = false;

  String? _error;
  Map<String, dynamic>? _provider;
  bool _hasProvider = false;

  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    codeController.dispose();
    super.dispose();
  }

  Future<void> _loadProvider() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _settingsService.getProvider();

      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _hasProvider = response['has_provider'] == true;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load provider details.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _requestProvider() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Please enter a valid therapist email.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final response = await _settingsService.requestProvider(
        providerEmail: email,
        providerName: name.isEmpty ? null : name,
      );

      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _hasProvider = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent to therapist.'),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to send provider request.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  Future<void> _verifyProvider() async {
    final code = codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _error = 'Please enter the verification code.';
      });
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      final response = await _settingsService.verifyProvider(code: code);

      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _hasProvider = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider verified successfully.'),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to verify provider.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _verifying = false;
        });
      }
    }
  }

  Future<void> _removeProvider() async {
    setState(() {
      _removing = true;
      _error = null;
    });

    try {
      await _settingsService.removeProvider();

      setState(() {
        _provider = null;
        _hasProvider = false;
        emailController.clear();
        nameController.clear();
        codeController.clear();
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider removed successfully.'),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to remove provider.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _removing = false;
        });
      }
    }
  }

  bool get _hasPendingProvider {
    final status = _provider?['status']?.toString();
    return _provider != null && status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
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
                        'Care Provider',
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                        ),
                      ),

                      2.sh,

                      Text(
                        _hasProvider
                            ? 'Your therapist is connected to your account.'
                            : _hasPendingProvider
                                ? 'A verification code has been sent. Enter the code to complete connection.'
                                : 'Add your personal therapist by entering their email address.',
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

                      if (_hasProvider)
                        _therapistCard()
                      else if (_hasPendingProvider)
                        _pendingVerification()
                      else
                        _addTherapistForm(),

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
              const Icon(
                Icons.chevron_left,
                size: 22,
                color: AppColors.darkGrey,
              ),
              Text(
                'Back',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              'Provider',
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

  Widget _addTherapistForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Therapist Name'),
        _inputField(
          controller: nameController,
          hintText: 'Dr Sarah Johnson',
        ),

        2.sh,

        _label('Therapist Email'),
        _inputField(
          controller: emailController,
          hintText: 'therapist@example.com',
          keyboardType: TextInputType.emailAddress,
        ),

        2.sh,

        Text(
          'A verification code will be sent to the therapist. Once confirmed, they will be linked to your account.',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.grey,
            height: 1.4,
          ),
        ),

        4.sh,

        AppButton(
          text: _sending ? 'Sending...' : 'Send Code',
          onPressed: _sending ? null : _requestProvider,
        ),
      ],
    );
  }

  Widget _pendingVerification() {
    final email = _provider?['provider_email']?.toString() ?? '';
    final name = _provider?['provider_name']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Pending Therapist' : name,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              1.sh,
              Text(
                email,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.grey,
                ),
              ),
              1.sh,
              Text(
                'Pending verification',
                style: AppTextStyles.body2.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        3.sh,

        _label('Verification Code'),
        _inputField(
          controller: codeController,
          hintText: 'Enter code',
        ),

        4.sh,

        AppButton(
          text: _verifying ? 'Verifying...' : 'Verify Provider',
          onPressed: _verifying ? null : _verifyProvider,
        ),

        2.sh,

        AppButton(
          text: _removing ? 'Removing...' : 'Cancel Request',
          onPressed: _removing ? null : _removeProvider,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _therapistCard() {
    final name = _provider?['provider_name']?.toString() ?? 'Therapist';
    final email = _provider?['provider_email']?.toString() ?? '';
    final phone = _provider?['provider_phone']?.toString() ?? '';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: AppColors.primary,
                ),
              ),

              4.sw,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    0.8.sh,
                    Text(
                      email,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      0.8.sh,
                      Text(
                        phone,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                    0.8.sh,
                    Text(
                      'Connected',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        3.sh,

        AppButton(
          text: _removing ? 'Removing...' : 'Remove Provider',
          onPressed: _removing ? null : _removeProvider,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Text(
        text,
        style: AppTextStyles.body2.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.body1.copyWith(
        color: AppColors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body2.copyWith(
          color: AppColors.grey,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4.w,
          vertical: 1.8.h,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4EA),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}