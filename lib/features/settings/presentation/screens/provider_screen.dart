import 'package:cozy_health/core/widgets/friendly_error.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/settings_service.dart';

class ProviderScreen extends StatefulWidget {
  const ProviderScreen({super.key, this.settingsService});

  final SettingsService? settingsService;

  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen> {
  late final SettingsService _settingsService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  bool _verifying = false;
  bool _removing = false;
  String? _updatingConsent;

  String? _error;
  int _failures = 0;
  VoidCallback? _retry;
  Map<String, dynamic>? _provider;
  bool _hasProvider = false;

  @override
  void initState() {
    super.initState();
    _settingsService = widget.settingsService ?? SettingsService();
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
    _retry = _loadProvider;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _settingsService.getProvider();

      if (!mounted) return;
      _failures = 0;
      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _hasProvider = response['has_provider'] == true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _failures++;
      setState(() {
        _error = AppSnackbar.friendly(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      _failures++;
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
    _retry = _requestProvider;
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

      if (!mounted) return;
      _failures = 0;
      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _hasProvider = response['has_provider'] == true;
      });

      if (!mounted) return;

      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text('Verification code sent to therapist.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _failures++;
      setState(() {
        _error = AppSnackbar.friendly(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      _failures++;
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
    _retry = _verifyProvider;
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

      if (!mounted) return;
      _failures = 0;
      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _hasProvider = true;
      });

      if (!mounted) return;

      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text('Provider verified successfully.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _failures++;
      setState(() {
        _error = AppSnackbar.friendly(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      _failures++;
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
    _retry = _removeProvider;
    setState(() {
      _removing = true;
      _error = null;
    });

    try {
      await _settingsService.removeProvider();
      if (!mounted) return;
      _failures = 0;

      setState(() {
        _provider = null;
        _hasProvider = false;
        emailController.clear();
        nameController.clear();
        codeController.clear();
      });

      if (!mounted) return;

      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(content: Text('Provider removed successfully.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _failures++;
      setState(() {
        _error = AppSnackbar.friendly(e.message);
      });
    } catch (_) {
      if (!mounted) return;
      _failures++;
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

  Future<void> _updateConsent(String type, bool value) async {
    final linkId = _provider?['link_id'] ?? _provider?['id'];
    if (linkId == null || _updatingConsent != null || _removing) return;
    _retry = () => _updateConsent(type, value);
    setState(() {
      _updatingConsent = type;
      _error = null;
    });
    try {
      await _settingsService.updateConsent(
        linkId: linkId.toString(),
        consentType: type,
        value: value,
      );
      if (!mounted) return;
      setState(() {
        final flags = Map<String, dynamic>.from(
          _provider?['consent_flags'] as Map? ?? {},
        );
        flags[type] = value;
        _provider = {...?_provider, 'consent_flags': flags};
        _failures = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Unable to save consent. Your sharing setting has not changed.';
        _failures++;
      });
    } finally {
      if (mounted) setState(() => _updatingConsent = null);
    }
  }

  Future<void> _confirmRevoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke provider access?'),
        content: const Text(
          'Your provider will lose access to your shared data and cannot add notes. You can reconnect later; all sharing choices will start off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke access'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _revokeAccess();
  }

  Future<void> _revokeAccess() async {
    final linkId = _provider?['link_id'] ?? _provider?['id'];
    if (linkId == null || _removing || _updatingConsent != null) return;
    _retry = _confirmRevoke;
    setState(() {
      _removing = true;
      _error = null;
    });
    try {
      await _settingsService.revokeProviderAccess(linkId.toString());
      if (!mounted) return;
      setState(() {
        _provider = null;
        _hasProvider = false;
      });
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to revoke access. Please try again.';
        _failures++;
      });
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  Widget _consentToggles() {
    final flags = _provider?['consent_flags'] as Map? ?? {};
    const labels = {
      'moods': 'Share mood entries',
      'journals': 'Share journal summaries',
      'quizzes': 'Share quiz results',
      'notes': 'Allow provider notes',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose what this provider can access until you revoke access. Turn off a switch to stop sharing that data type.',
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        for (final entry in labels.entries)
          SwitchListTile.adaptive(
            key: ValueKey('consent-${entry.key}'),
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value),
            subtitle: entry.key == 'journals'
                ? const Text(
                    'Metadata only: title, type, word count and date. Your journal body, transcript and recordings are never shared.',
                  )
                : null,
            value: flags[entry.key] == true,
            onChanged: _updatingConsent != null || _removing
                ? null
                : (value) => _updateConsent(entry.key, value),
          ),
        if (_updatingConsent != null) const LinearProgressIndicator(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: _loading
              ? Center(child: CircularProgressIndicator())
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
                        FriendlyError(
                          title: 'Something needs another look.',
                          message: _error!,
                          onRetry: _retry,
                          failureCount: _failures,
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
              Icon(Icons.chevron_left, size: 22, color: AppColors.darkGrey),
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
        _inputField(controller: nameController, hintText: 'Dr Sarah Johnson'),

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
          isLoading: _sending,
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
                style: AppTextStyles.body2.copyWith(color: AppColors.grey),
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
        _inputField(controller: codeController, hintText: 'Enter code'),

        4.sh,

        AppButton(
          isLoading: _verifying,
          text: _verifying ? 'Verifying...' : 'Verify Provider',
          onPressed: _verifying ? null : _verifyProvider,
        ),

        2.sh,

        AppButton(
          isLoading: _removing,
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
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: Theme.of(context).colorScheme.primary,
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
                      _provider?['provider_verified'] == true
                          ? 'Link verified • Provider verified'
                          : 'Link verified • Provider verification pending',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.primary,
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

        _consentToggles(),

        3.sh,

        AppButton(
          isLoading: _removing,
          text: _removing ? 'Revoking...' : 'Revoke access',
          onPressed: _removing || _updatingConsent != null
              ? null
              : _confirmRevoke,
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
      style: AppTextStyles.body1.copyWith(color: AppColors.black, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body2.copyWith(color: AppColors.grey),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFFE1E4EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
