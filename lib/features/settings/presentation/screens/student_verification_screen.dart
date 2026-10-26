import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/widgets/app_button.dart';

class StudentVerificationScreen extends StatefulWidget {
  const StudentVerificationScreen({super.key});
  @override
  State<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState extends State<StudentVerificationScreen> {
  final _institution = TextEditingController(),
      _email = TextEditingController();
  final _owner = LocalDbService().activeUserId;
  PlatformFile? _file;
  Map<String, dynamic>? _application;
  bool _enabled = false, _busy = false, _acknowledged = false;
  bool _loading = true, _loadFailed = false, _resubmitting = false;
  String? _message;
  bool get _showForm =>
      !_loading && !_loadFailed && (_application == null || _resubmitting);
  bool get _canReapply {
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
    _load();
  }

  @override
  void dispose() {
    _institution.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted || _owner != LocalDbService().activeUserId) return;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final response = await ApiClient().get('/student-verification');
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      final data = response.data as Map;
      setState(() {
        _enabled = data['enabled'] == true;
        _application = data['application'] == null
            ? null
            : Map<String, dynamic>.from(data['application'] as Map);
        _loading = false;
        _resubmitting = false;
      });
    } catch (_) {
      if (mounted && _owner == LocalDbService().activeUserId) {
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
    if (!mounted || file == null) return;
    final length = await file.length();
    if (!mounted) return;
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
      if (bytes == null ||
          bytes.length > 3 * 1024 * 1024 ||
          _owner != LocalDbService().activeUserId) {
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
      if (mounted && _owner == LocalDbService().activeUserId) {
        setState(() {
          _file = null;
          _message =
              'Submitted for manual review. An institution email alone does not establish eligibility.';
        });
        await _load();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not submit. Check for an existing pending application before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student verification')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'An admin reviews your current enrolment. Upload a current course form, enrolment letter or transcript showing your name, institution and current academic term. Cover grades and unrelated details. Approval lasts 12 months and must be renewed.',
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
            TextField(
              controller: _institution,
              decoration: const InputDecoration(labelText: 'Institution'),
            ),
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: 'Institution email (optional)',
              ),
              keyboardType: TextInputType.emailAddress,
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
          if (_application?['id'] is String &&
              _application?['status'] == 'pending' &&
              _application?['institution_email'] != null)
            AppButton(
              text: 'Verify institution email',
              isOutlined: true,
              onPressed: () async {
                try {
                  await ApiClient().post(
                    '/student-verification/${_application?['id']}/verify-email',
                  );
                  if (mounted) {
                    setState(() => _message = 'Check your institution inbox.');
                  }
                } catch (_) {
                  if (mounted) {
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
