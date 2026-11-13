import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/security_blur.dart';

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});
  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  final _institution = TextEditingController(),
      _email = TextEditingController();
  final _confirmation = TextEditingController();
  final _owner = LocalDbService().activeUserId;
  StreamSubscription<void>? _accountSubscription;
  bool _accountChanged = false;
  bool get _ownsAccount =>
      !_accountChanged && _owner == LocalDbService().activeUserId;
  Map<String, dynamic>? _application;
  Map<String, dynamic>? _eligibility;
  String? _challengeId;
  final _website = TextEditingController();
  List<Map<String, dynamic>> _schoolRequests = [];
  bool _requestSchool = false;
  bool _privacyExpanded = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  bool _enabled = false, _busy = false;
  bool _loading = true, _loadFailed = false, _resubmitting = false;
  String? _message;
  bool get _showForm =>
      !_loading && !_loadFailed && (_application == null || _resubmitting);
  bool get _canReapply {
    if (_application?['status'] == 'pending') return false;
    if (_eligibility != null) return _eligibility?['renewal_available'] == true;
    final status = _application?['status'];
    if (status == 'rejected' || status == 'expired') return true;
    final until = DateTime.tryParse(
      _application?['eligible_until']?.toString() ?? '',
    );
    return status == 'approved' &&
        until != null &&
        !until.isAfter(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _accountSubscription = LocalDbService().accountChanges.listen((_) {
      if (!mounted || _owner == LocalDbService().activeUserId) return;
      _institution.clear();
      _email.clear();
      _confirmation.clear();
      setState(() {
        _accountChanged = true;
        _application = null;
        _eligibility = null;
        _challengeId = null;
        _message = null;
      });
    });
    _load();
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    _resendTimer?.cancel();
    _website.dispose();
    _institution.dispose();
    _email.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || !_ownsAccount) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final response = await ApiClient().get('/student-verification');
      final schools = await ApiClient().get('/student-school-requests');
      if (!mounted || !_ownsAccount) return;
      final data = response.data as Map;
      setState(() {
        _schoolRequests = schools.data is Map && schools.data['data'] is List
            ? (schools.data['data'] as List)
                  .whereType<Map>()
                  .map((r) => Map<String, dynamic>.from(r))
                  .toList()
            : [];
        _enabled = data['enabled'] == true;
        _application = data['application'] == null
            ? null
            : Map<String, dynamic>.from(data['application'] as Map);
        _eligibility = data['eligibility'] is Map
            ? Map<String, dynamic>.from(data['eligibility'] as Map)
            : null;
        final challenge = data['email_challenge'];
        _challengeId = challenge is Map ? challenge['id'] as String? : null;
        _loading = false;
        _resubmitting = false;
      });
    } catch (_) {
      if (mounted && _ownsAccount) {
        setState(() {
          _loading = false;
          _loadFailed = true;
          _message = 'Could not load your application. Please retry.';
        });
      }
    }
  }

  String _failure(Object error, String fallback) {
    if (error is ApiException) return error.message;
    if (error is DioException && error.response?.data is Map) {
      final message = (error.response!.data as Map)['message'];
      if (message is String) return message;
    }
    return fallback;
  }

  Future<void> _requestEmail() async {
    if (_busy ||
        _resendSeconds > 0 ||
        !_enabled ||
        _email.text.trim().isEmpty ||
        !_ownsAccount) {
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await ApiClient().post(
        '/student-verification/email',
        data: {'email': _email.text.trim()},
      );
      if (!mounted || !_ownsAccount) return;
      setState(() {
        _challengeId = (response.data as Map)['challenge_id'] as String?;
        _confirmation.clear();
        _message = 'Check your school inbox. Enter the code within 10 minutes.';
        _resendSeconds = 60;
        _resendTimer?.cancel();
        _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted || !_ownsAccount || _resendSeconds <= 1) {
            timer.cancel();
            if (mounted) setState(() => _resendSeconds = 0);
          } else {
            setState(() => _resendSeconds--);
          }
        });
      });
    } catch (error) {
      if (mounted && _ownsAccount) {
        setState(
          () => _message = _failure(
            error,
            'Could not send verification. Retry or request to add your school.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmEmail() async {
    if (_busy || !_enabled || _challengeId == null || !_ownsAccount) return;
    var token = _confirmation.text.trim();
    var id = _challengeId!;
    final link = Uri.tryParse(token);
    if (link != null && link.hasScheme) {
      id = link.queryParameters['id'] ?? id;
      token = link.queryParameters['token'] ?? '';
    }
    setState(() => _busy = true);
    try {
      await ApiClient().post(
        '/student-verification/email/confirm',
        data: {'id': id, 'token': token},
      );
      if (!mounted || !_ownsAccount) return;
      setState(() {
        _confirmation.clear();
        _message =
            'Student eligibility verified. A separate store purchase is required for paid access.';
      });
      await _load();
    } catch (error) {
      if (mounted && _ownsAccount) {
        setState(
          () => _message = _failure(
            error,
            'Could not confirm. Check the code or request a new verification email.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitSchool() async {
    if (_busy || !_ownsAccount) return;
    final address = _email.text.trim();
    if (!address.contains('@') ||
        _institution.text.trim().isEmpty ||
        _website.text.trim().isEmpty) {
      setState(
        () => _message =
            'Enter your school email, institution name and official website.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ApiClient().post(
        '/student-school-requests',
        data: {
          'domain': address.split('@').last.toLowerCase(),
          'institution': _institution.text.trim(),
          'website': _website.text.trim(),
        },
      );
      if (!mounted || !_ownsAccount) return;
      setState(() {
        _requestSchool = false;
        _message =
            'School request submitted. Approval still requires you to verify your own mailbox.';
      });
      await _load();
    } catch (error) {
      if (mounted && _ownsAccount) {
        setState(
          () => _message = _failure(
            error,
            'Could not submit your school request. Please retry.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SecurityBlur(
    child: _ownsAccount
        ? _buildVerification(context)
        : const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text(
                  'Account changed. Reopen Student verification from your settings.',
                ),
              ),
            ),
          ),
  );

  String _date(Object? value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    return date == null
        ? 'Not available'
        : DateFormat.yMMMd().format(date.toLocal());
  }

  String _status(Object? value) => switch (value) {
    'pending' => 'Awaiting review',
    'approved' => 'Approved',
    'rejected' => 'Not approved',
    'expired' => 'Expired',
    _ => 'Status unavailable',
  };

  Widget _section(
    BuildContext context,
    List<Widget> children, {
    bool tinted = false,
  }) {
    final w = context.cozyColors.wellness;
    return Padding(
      padding: EdgeInsets.only(bottom: w.gap),
      child: WellnessPanel(
        tinted: tinted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(height: w.contentGap),
              children[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, String text) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);

  Widget _plansAction() => WellnessAction(
    key: const ValueKey('student-return-plans'),
    label: 'View plans',
    onPressed: () => context.go('/wellness/packages'),
  );

  Widget _buildVerification(BuildContext context) {
    final w = context.cozyColors.wellness;
    final active = _eligibility?['active'] == true;
    final approved = _application?['status'] == 'approved';
    return Scaffold(
      appBar: AppBar(title: const Text('Student verification')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(w.page),
          children: [
            _section(context, [
              _heading(context, 'Student pricing, with your school email'),
              const Text(
                'Verify a Nigerian tertiary school email ending in .edu.ng or an approved institution domain. Use your existing Cozy account.',
              ),
              const Text(
                'Verification enables Student pricing. Paid access starts only after Apple or Google confirms your purchase.',
              ),
            ], tinted: true),
            if (_loading) const Text('Loading your application...'),
            if (_loadFailed)
              AppButton(text: 'Retry application', onPressed: _load),
            if (_application != null || active)
              _section(context, [
                _heading(
                  context,
                  active
                      ? 'Student eligibility active'
                      : 'Application: ${_status(_application?['status'])}',
                ),
                if (_application != null && active)
                  Text('Application: ${_status(_application?['status'])}'),
                if ((_application?['review_note']?.toString().trim() ?? '')
                    .isNotEmpty)
                  Text(_application!['review_note'].toString()),
                if (_application?['eligible_until'] != null)
                  Text(
                    'Eligible until: ${_date(_application?['eligible_until'])}',
                  ),
                if (active)
                  Text(
                    'Current eligibility ends: ${_date(_eligibility?['expires_at'])}',
                  ),
                if (_eligibility?['renewal_reminder'] == true)
                  const Text(
                    'Renew your Student eligibility now. Your already-paid subscription period is preserved.',
                  ),
                if (_application?['status'] == 'pending') ...[
                  const Text(
                    'Your application is awaiting review and cannot be edited.',
                  ),
                  AppButton(
                    text: 'Refresh application status',
                    isOutlined: true,
                    onPressed: _busy || _loading ? null : _load,
                  ),
                ],
                if (active || approved) ...[
                  const Text(
                    'Eligibility does not activate a paid plan. Complete a separate store purchase for paid access.',
                  ),
                  _plansAction(),
                ],
              ]),
            if (!_loading && !_loadFailed && !_enabled)
              _section(context, [
                const Text('Student applications are not open yet.'),
              ]),
            if (_canReapply && !_resubmitting)
              _section(context, [
                AppButton(
                  text: approved
                      ? 'Renew student eligibility'
                      : 'Verify school email',
                  onPressed: !_enabled || _busy
                      ? null
                      : () => setState(() {
                          _resubmitting = true;
                          _message = null;
                        }),
                ),
                AppButton(
                  text: 'Choose another plan',
                  isOutlined: true,
                  onPressed: () => context.push('/wellness/packages'),
                ),
              ]),
            if (_showForm)
              _section(context, [
                _heading(
                  context,
                  _challengeId == null
                      ? '1. Enter your school email'
                      : '1. Verification email sent',
                ),
                TextField(
                  key: const ValueKey('student-school-email'),
                  controller: _email,
                  enabled: !_busy && _enabled,
                  decoration: const InputDecoration(labelText: 'School email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const Text(
                  'We send a single-use six-digit code, valid for 10 minutes with three attempts.',
                ),
                AppButton(
                  key: const ValueKey('student-email-request'),
                  text: _resendSeconds > 0
                      ? 'Resend in $_resendSeconds seconds'
                      : _challengeId == null
                      ? 'Send verification email'
                      : 'Resend verification email',
                  isLoading: _busy,
                  onPressed: !_enabled || _busy || _resendSeconds > 0
                      ? null
                      : _requestEmail,
                ),
              ]),
            if (_challengeId != null && !_loading && !_loadFailed)
              _section(context, [
                _heading(context, '2. Confirm your school email'),
                const Text(
                  'Open your school inbox and enter the code or paste the verification link.',
                ),
                TextField(
                  key: const ValueKey('student-email-code'),
                  controller: _confirmation,
                  enabled: !_busy && _enabled,
                  decoration: const InputDecoration(
                    labelText: 'Verification code or link',
                  ),
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableSuggestions: false,
                  autocorrect: false,
                ),
                AppButton(
                  key: const ValueKey('student-email-confirm'),
                  text: 'Confirm school email',
                  isLoading: _busy,
                  onPressed: !_enabled || _busy ? null : _confirmEmail,
                ),
              ]),
            if (_message != null)
              _section(context, [
                Semantics(liveRegion: true, child: Text(_message!)),
              ], tinted: true),
            if (_showForm || _schoolRequests.isNotEmpty)
              _section(context, [
                _heading(context, 'School not supported?'),
                if (_showForm)
                  AppButton(
                    key: const ValueKey('student-school-request-toggle'),
                    text: 'Request to add my school',
                    isOutlined: true,
                    onPressed: _busy
                        ? null
                        : () =>
                              setState(() => _requestSchool = !_requestSchool),
                  ),
                if (_requestSchool && _showForm) ...[
                  const Text(
                    'Use the school email above, then add your institution details. Adding a school does not verify your mailbox.',
                  ),
                  TextField(
                    key: const ValueKey('student-school-institution'),
                    controller: _institution,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Institution name',
                    ),
                  ),
                  TextField(
                    key: const ValueKey('student-school-website'),
                    controller: _website,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Official school website',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  AppButton(
                    key: const ValueKey('student-school-request-submit'),
                    text: 'Submit school request',
                    onPressed: !_enabled || _busy ? null : _submitSchool,
                  ),
                ],
                for (final school in _schoolRequests)
                  Text(
                    'School request: ${school['institution']} - ${_status(school['status'])}',
                  ),
              ]),
            _section(context, [
              _heading(context, 'Eligibility and privacy'),
              const Text(
                'Eligibility lasts 12 months; renewal opens 30 days before expiry. Your school email is private and never shared with providers.',
              ),
              WellnessAction(
                key: const ValueKey('student-privacy-details'),
                label: _privacyExpanded
                    ? 'Hide verification and privacy details'
                    : 'How verification and privacy work',
                icon: _privacyExpanded ? Icons.expand_less : Icons.expand_more,
                onPressed: () =>
                    setState(() => _privacyExpanded = !_privacyExpanded),
              ),
              if (_privacyExpanded)
                const Text(
                  'This checks mailbox ownership, not current enrollment. Staff and alumni with working school mailboxes may qualify. Your school email is retained while eligible and for 90 days afterward; a protected email fingerprint prevents duplicate account claims until account deletion.',
                ),
              const Text(
                'Questions or appeals: Team@cozyhealth.org. Student eligibility does not activate a paid plan; a separate store purchase is required.',
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
