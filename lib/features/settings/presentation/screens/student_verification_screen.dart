import 'dart:async';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  PlatformFile? _file;
  Map<String, dynamic>? _application;
  Map<String, dynamic>? _eligibility;
  String? _challengeId;
  bool _emailRoute = false;
  bool _enabled = false, _busy = false, _acknowledged = false;
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
        _file = null;
        _message = null;
      });
    });
    _load();
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
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
      if (!mounted || !_ownsAccount) return;
      final data = response.data as Map;
      setState(() {
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

  Future<void> _choose() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (!mounted || file == null || !_ownsAccount) return;
    final length = await file.length();
    if (!mounted || !_ownsAccount) return;
    setState(() {
      if (length == null || length > 3 * 1024 * 1024) {
        _message = 'Choose a file no larger than 3 MB.';
      } else {
        _file = file;
        _message = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_file == null ||
        !_showForm ||
        !_enabled ||
        !_acknowledged ||
        _institution.text.trim().isEmpty ||
        _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await _file?.readAsBytes();
      if (bytes == null || bytes.length > 3 * 1024 * 1024 || !_ownsAccount) {
        return;
      }
      await ApiClient().post(
        '/student-verification',
        data: FormData.fromMap({
          'institution': _institution.text.trim(),
          if (_email.text.trim().isNotEmpty)
            'institution_email': _email.text.trim(),
          'acknowledged': '1',
          'evidence': MultipartFile.fromBytes(bytes, filename: _file?.name),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      if (mounted && _ownsAccount) {
        setState(() {
          _file = null;
          _message =
              'Submitted for private admin review of your current enrolment.';
        });
        await _load();
      }
    } catch (_) {
      if (mounted && _ownsAccount) {
        setState(
          () => _message =
              'Could not submit. Check for an existing pending application before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
    if (_busy || !_enabled || _email.text.trim().isEmpty || !_ownsAccount) {
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
        _message = 'Check your school inbox. Enter the code within 15 minutes.';
      });
    } catch (error) {
      if (mounted && _ownsAccount) {
        setState(
          () => _message = _failure(
            error,
            'Could not send verification. Retry or submit enrolment documents.',
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

  Widget _buildVerification(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student verification')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Verify a school email on an approved student-only domain, or submit recent documents for admin review. Use your existing account even if you sign in with a different email. Eligibility lasts 12 months; renewal opens 30 days before expiry.',
          ),
          const Text(
            'Your submission is locked while it is reviewed. Documents are deleted after approval or rejection, or after 14 days without a decision.',
          ),
          if (_loading) const Text('Loading your application...'),
          if (_loadFailed)
            AppButton(text: 'Retry application', onPressed: _load),
          if (_application != null)
            Text(
              'Application: ${_application?['status']}\n${_application?['review_note'] ?? ''}\nEligible until: ${_application?['eligible_until'] ?? 'Not approved'}',
            ),
          if (_eligibility?['active'] == true)
            Text('Current eligibility ends: ${_eligibility?['expires_at']}'),
          if (_eligibility?['renewal_reminder'] == true)
            const Text(
              'Renew your Student eligibility now. Your already-paid subscription period is preserved.',
            ),
          if (!_enabled) const Text('Student applications are not open yet.'),
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
          if (_canReapply && !_resubmitting) ...[
            AppButton(
              text: _application?['status'] == 'approved'
                  ? 'Renew student eligibility'
                  : 'Submit new evidence',
              onPressed: !_enabled || _busy
                  ? null
                  : () => setState(() {
                      _resubmitting = true;
                      _file = null;
                      _acknowledged = false;
                      _message = null;
                    }),
            ),
            AppButton(
              text: 'Choose another plan',
              isOutlined: true,
              onPressed: () => context.push('/wellness/packages'),
            ),
          ],
          if (_showForm) ...[
            AppButton(
              key: const ValueKey('student-email-route'),
              text: 'Use school email',
              isOutlined: !_emailRoute,
              onPressed: _busy
                  ? null
                  : () => setState(() => _emailRoute = true),
            ),
            AppButton(
              key: const ValueKey('student-document-route'),
              text: 'Use enrolment documents',
              isOutlined: _emailRoute,
              onPressed: _busy
                  ? null
                  : () => setState(() => _emailRoute = false),
            ),
            if (!_emailRoute)
              TextField(
                controller: _institution,
                decoration: const InputDecoration(labelText: 'Institution'),
              ),
            TextField(
              controller: _email,
              decoration: InputDecoration(
                labelText: _emailRoute
                    ? 'School email'
                    : 'Institution email (optional)',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            if (_emailRoute) ...[
              const Text(
                'Only approved student-only domains qualify automatically. Verify ownership using the code sent to your school inbox. For other domains, use enrolment documents.',
              ),
              AppButton(
                key: const ValueKey('student-email-request'),
                text: 'Send verification email',
                isLoading: _busy,
                onPressed: !_enabled || _busy ? null : _requestEmail,
              ),
            ],
            if (!_emailRoute) ...[
              const Text(
                'Upload a current-term enrolment letter, registration record or student ID showing current validity, your name and institution. Cover unrelated details.',
              ),
              const SizedBox(height: 16),
              AppButton(
                key: const ValueKey('student-evidence'),
                text: _file?.name ?? 'Choose enrolment evidence · PDF or image',
                isOutlined: true,
                onPressed: !_enabled || _busy ? null : _choose,
              ),
              CheckboxListTile(
                value: _acknowledged,
                onChanged: !_enabled || _busy
                    ? null
                    : (value) => setState(() => _acknowledged = value == true),
                title: const Text(
                  'I authorize private review of this evidence for Student eligibility.',
                ),
              ),
              AppButton(
                key: const ValueKey('student-submit'),
                text: 'Submit for review',
                isLoading: _busy,
                onPressed: !_enabled || !_acknowledged || _file == null
                    ? null
                    : _submit,
              ),
            ],
          ],
          if (_challengeId != null && !_loading && !_loadFailed) ...[
            TextField(
              key: const ValueKey('student-email-code'),
              controller: _confirmation,
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
          ],
          if (_application?['id'] is String &&
              _application?['status'] == 'pending' &&
              _application?['institution_email'] != null)
            AppButton(
              text: 'Verify institution email',
              isOutlined: true,
              onPressed: () async {
                if (!_ownsAccount || _busy) return;
                try {
                  await ApiClient().post(
                    '/student-verification/${_application?['id']}/verify-email',
                  );
                  if (mounted && _ownsAccount) {
                    setState(() => _message = 'Check your institution inbox.');
                  }
                } catch (_) {
                  if (mounted && _ownsAccount) {
                    setState(
                      () => _message =
                          'Could not send verification. Manual review remains available.',
                    );
                  }
                }
              },
            ),
          if (_message != null) Text(_message!),
          const Text(
            'Questions or appeals: Team@cozyhealth.org. Student eligibility does not activate a paid plan; a separate store purchase is required.',
          ),
        ],
      ),
    ),
  );
}
