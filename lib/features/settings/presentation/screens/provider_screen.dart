import '../../../../core/services/network_status.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
import 'provider_resources_screen.dart';

class ProviderScreen extends StatefulWidget {
  const ProviderScreen({super.key, this.settingsService});

  final SettingsService? settingsService;

  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen>
    with WidgetsBindingObserver {
  late final SettingsService _settingsService;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  final Map<String, bool> _invitationFlags = {
    'moods': false,
    'journals': false,
    'quizzes': false,
    'notes': false,
  };
  Timer? _resendTimer;
  Timer? _invitationExpiryTimer;
  bool _invitationExpired = true;
  int _resendSeconds = 0;
  bool get _offline => networkOffline.value == true;
  void _connectionChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_offline) _loadProvider();
  }

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
  bool _showResources = false;
  String? _correctionEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    networkOffline.addListener(_connectionChanged);
    _settingsService = widget.settingsService ?? SettingsService();
    _loadProvider();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    networkOffline.removeListener(_connectionChanged);
    _resendTimer?.cancel();
    emailController.dispose();
    _invitationExpiryTimer?.cancel();
    nameController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_sending &&
        !_removing &&
        !_verifying) {
      _loadProvider();
    }
  }

  void _startResendCooldown(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    if (seconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
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
      if (provider is Map &&
          provider['verification_actor'] == 'provider' &&
          response['has_provider'] != true) {
        final sentAt = DateTime.tryParse(
          provider['invitation_sent_at']?.toString() ?? '',
        );
        final remaining = sentAt == null
            ? 0
            : 60 - DateTime.now().difference(sentAt).inSeconds;
        _startResendCooldown(remaining.clamp(0, 60));
      }

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _scheduleInvitationExpiry();
        _hasProvider = response['has_provider'] == true;
        if (_provider?['verification_actor'] == 'provider' && !_hasProvider) {
          final flags = _provider?['consent_flags'] as Map? ?? {};
          for (final type in _invitationFlags.keys) {
            _invitationFlags[type] = flags[type] == true;
          }
        }
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
    if (_sending || _removing) return;
    _retry = _requestProvider;
    final email = emailController.text.trim().isNotEmpty
        ? emailController.text.trim()
        : _provider?['provider_email']?.toString() ?? '';
    final name = nameController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Please enter a valid therapist email.';
      });
      return;
    }

    setState(() {
      _sending = true;
      _provider?['invitation_code'] = null;
      _error = null;
    });

    try {
      final response = await _settingsService.requestProvider(
        providerEmail: email,
        providerName: name.isEmpty ? null : name,
        consentFlags: Map<String, bool>.from(_invitationFlags),
      );

      if (!mounted) return;
      _failures = 0;
      final provider = response['provider'];

      setState(() {
        _provider = provider is Map<String, dynamic> ? provider : null;
        _scheduleInvitationExpiry();
        _hasProvider = response['has_provider'] == true;
      });

      if (!mounted) return;
      if (!_hasProvider) {
        _startResendCooldown(60);
      }

      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(
          content: Text(
            _hasProvider
                ? 'Your provider is already connected.'
                : 'Invitation email queued for your provider.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 503) {
        await _loadProvider();
        if (!mounted) return;
        _retry = _requestProvider;
      }
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
        _scheduleInvitationExpiry();
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
      _resendTimer?.cancel();
      _resendSeconds = 0;
      if (!mounted) return;
      _failures = 0;

      setState(() {
        _provider = null;
        _hasProvider = false;
        emailController.clear();
        nameController.clear();
        codeController.clear();
        for (final type in _invitationFlags.keys) {
          _invitationFlags[type] = false;
        }
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
        scrollable: true,
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
      'quizzes': 'Share assessment results',
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
            onChanged: _offline || _updatingConsent != null || _removing
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      2.sh,

                      Text(
                        _hasProvider
                            ? 'Your therapist is connected to your account.'
                            : _hasPendingProvider
                            ? (_provider?['verification_actor'] == 'provider'
                                  ? 'Your provider will enter the emailed code in their dashboard to connect.'
                                  : 'Enter the verification code to complete your existing request.')
                            : 'Add your personal therapist by entering their email address.',
                        style: AppTextStyles.body1.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              Icon(
                Icons.chevron_left,
                size: 22,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              Text(
                'Back',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.onSurface,
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
          'Choose what to share. Cozy will email your provider a connection code. They will review your choices before connecting.',
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),

        4.sh,

        _invitationChoices(),
        2.sh,
        AppButton(
          isLoading: _sending,
          text: _sending ? 'Sending...' : 'Send invitation',
          onPressed: _offline || _sending ? null : _requestProvider,
        ),
      ],
    );
  }

  Widget _invitationChoices() {
    const labels = {
      'moods': 'Share mood entries, triggers and coping choices',
      'journals': 'Share journal summaries',
      'quizzes': 'Share assessment results',
      'notes': 'Allow provider notes',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your sharing choices',
          style: AppTextStyles.heading3.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Text(
          'All choices start off. You can connect without sharing wellness information and change your choices later.',
        ),
        for (final entry in labels.entries)
          SwitchListTile.adaptive(
            key: ValueKey('invitation-${entry.key}'),
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value),
            subtitle: entry.key == 'journals'
                ? const Text(
                    'Titles, type, word count and dates only. Journal text, transcripts and recordings stay private.',
                  )
                : null,
            value: _invitationFlags[entry.key]!,
            onChanged: _offline || _sending
                ? null
                : (value) =>
                      setState(() => _invitationFlags[entry.key] = value),
          ),
      ],
    );
  }

  Future<void> _editProviderEmail() async {
    final original = _provider?['provider_email']?.toString() ?? '';
    var corrected = _correctionEmail ?? original;
    final formKey = GlobalKey<FormState>();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Correct provider email'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sending to the corrected address cancels the old invitation and replaces its code. Your sharing choices will stay the same.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: corrected,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correct provider email',
                  ),
                  onChanged: (value) => corrected = value,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (!RegExp(
                          r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                        ).hasMatch(email) ||
                        email.length > 190) {
                      return 'Enter a valid email address.';
                    }
                    if (email.toLowerCase() == original.toLowerCase()) {
                      return 'Enter a different email address.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep current invitation'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, corrected.trim());
              }
            },
            child: const Text('Send corrected invitation'),
          ),
        ],
      ),
    );
    if (email != null && mounted) {
      await _correctProviderEmail(email);
    }
  }

  Future<void> _correctProviderEmail(String email) async {
    if (_sending || _removing || _hasProvider || _provider == null) return;
    final linkId = (_provider!['link_id'] ?? _provider!['id']).toString();
    final name = _provider!['provider_name']?.toString() ?? '';
    final flags = Map<String, bool>.from(_invitationFlags);
    _correctionEmail = email;
    _retry = () => _correctProviderEmail(email);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _settingsService.cancelProviderInvitation(linkId);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        await _loadProvider();
        if (!mounted) return;
      }
      setState(() {
        _sending = false;
        _error = e.statusCode == 409
            ? 'Your provider already accepted. The connection has been refreshed.'
            : 'Unable to cancel the original invitation. Please retry.';
      });
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Unable to cancel the original invitation. Please retry.';
        });
      }
      return;
    }
    if (!mounted) return;
    _resendTimer?.cancel();
    _invitationExpiryTimer?.cancel();
    setState(() {
      _provider = null;
      _hasProvider = false;
      _resendSeconds = 0;
      emailController.text = email;
      nameController.text = name;
      _invitationFlags.addAll(flags);
      _sending = false;
      _correctionEmail = null;
    });
    await _requestProvider();
  }

  DateTime? get _invitationExpiresAt =>
      DateTime.tryParse(_provider?['invitation_expires_at']?.toString() ?? '');

  bool get _canShareInvitation =>
      !_hasProvider &&
      !_invitationExpired &&
      _provider?['verification_actor'] == 'provider' &&
      _provider?['invitation_code'] != null &&
      _invitationExpiresAt?.isAfter(DateTime.now()) == true;

  void _scheduleInvitationExpiry() {
    _invitationExpiryTimer?.cancel();
    final expires = _invitationExpiresAt;
    _invitationExpired = expires == null || !expires.isAfter(DateTime.now());
    if (expires != null && expires.isAfter(DateTime.now())) {
      _invitationExpiryTimer = Timer(expires.difference(DateTime.now()), () {
        if (mounted) setState(() => _invitationExpired = true);
      });
    }
  }

  Future<void> _copyInvitationCode() async {
    if (!_canShareInvitation || _sending) return;
    await Clipboard.setData(
      ClipboardData(text: _provider!['invitation_code'].toString()),
    );
    if (mounted) {
      AppSnackbar.show(
        context,
        AppSnackbar.fromLegacy(content: const Text('Connection code copied.')),
      );
    }
  }

  Future<void> _shareInvitation() async {
    if (!_canShareInvitation || _sending) return;
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              'I invited you to connect as my provider on Cozy Health. '
              'Sign in or register using ${_provider!['provider_email']}, then choose Accept patient invitation.\n'
              'Connection code: ${_provider!['invitation_code']}\n'
              'Expires: ${_invitationExpiresAt!.toUtc()}\n'
              '${_provider!['invitation_portal_url']}',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.fromLegacy(
            content: const Text(
              'Unable to open sharing. You can copy the code instead.',
            ),
          ),
        );
      }
    }
  }

  Widget _pendingInvitation() {
    final email = _provider?['provider_email']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Waiting for your provider',
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _provider?['invitation_sent_at'] == null
              ? 'The invitation email could not be queued. Resend it to $email or cancel this request.'
              : 'The invitation was queued for $email. Your provider signs in with this email and selects Accept patient invitation to enter the code. Codes expire after 15 minutes.',
        ),
        const SizedBox(height: 16),
        if (_canShareInvitation) ...[
          const Text('Your connection code'),
          SelectableText(
            _provider!['invitation_code'].toString(),
            key: const ValueKey('provider-invitation-code'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Expires ${_invitationExpiresAt!.toLocal().toString().substring(0, 16)}',
          ),
          const Text(
            'You can share this invitation elsewhere. Only the provider signed in with the invited email can accept it.',
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _sending ? null : _copyInvitationCode,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy code'),
              ),
              TextButton.icon(
                onPressed: _sending ? null : _shareInvitation,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share invitation'),
              ),
            ],
          ),
        ] else
          Text(
            _invitationExpiresAt != null && _invitationExpired
                ? 'This connection code has expired. Resend the invitation to get a new code.'
                : 'Resend the invitation to get a code you can copy or share.',
          ),
        const SizedBox(height: 16),
        for (final type in _invitationFlags.keys)
          Text(
            '${_invitationFlags[type]! ? "Selected to share" : "Private"}: $type',
          ),
        const SizedBox(height: 12),
        const Text(
          'No information is available to the provider until they confirm. You can cancel this invitation at any time.',
        ),
        const SizedBox(height: 24),
        AppButton(
          text: 'Check connection status',
          onPressed: _sending || _removing ? null : _loadProvider,
          isOutlined: true,
        ),
        const SizedBox(height: 12),
        AppButton(
          text: _resendSeconds > 0
              ? 'Resend in ${_resendSeconds}s'
              : 'Resend invitation',
          isLoading: _sending,
          onPressed: _offline || _sending || _removing || _resendSeconds > 0
              ? null
              : _requestProvider,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _offline || _sending || _removing
              ? null
              : _editProviderEmail,
          child: const Text('Wrong provider email?'),
        ),
        AppButton(
          text: 'Cancel request',
          isLoading: _removing,
          onPressed: _offline || _removing || _sending ? null : _removeProvider,
          isOutlined: true,
        ),
      ],
    );
  }

  Widget _pendingVerification() {
    if (_provider?['verification_actor'] == 'provider') {
      return _pendingInvitation();
    }
    final email = _provider?['provider_email']?.toString() ?? '';
    final name = _provider?['provider_name']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            border: AppSurface.border(context),
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Pending Therapist' : name,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              1.sh,
              Text(
                email,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              1.sh,
              Text(
                'Pending verification',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.warmOrange,
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
          onPressed: _offline || _verifying ? null : _verifyProvider,
        ),

        2.sh,

        AppButton(
          isLoading: _removing,
          text: _removing ? 'Removing...' : 'Cancel Request',
          onPressed: _offline || _removing ? null : _removeProvider,
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
            border: AppSurface.border(context),
            color: Theme.of(context).colorScheme.surface,
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    0.8.sh,
                    Text(
                      email,
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      0.8.sh,
                      Text(
                        phone,
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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

        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _showResources = false),
                child: Text(
                  'Sharing',
                  style: TextStyle(
                    fontWeight: !_showResources
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () => setState(() => _showResources = true),
                child: Text(
                  'Resources',
                  style: TextStyle(
                    fontWeight: _showResources
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_showResources)
          ProviderResourcesScreen(
            settingsService: _settingsService,
            embedded: true,
          )
        else
          _consentToggles(),

        3.sh,

        AppButton(
          isLoading: _removing,
          text: _removing ? 'Revoking...' : 'Revoke access',
          onPressed: _offline || _removing || _updatingConsent != null
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
          color: Theme.of(context).colorScheme.onSurface,
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
      readOnly: _offline,
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.body1.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body2.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}
