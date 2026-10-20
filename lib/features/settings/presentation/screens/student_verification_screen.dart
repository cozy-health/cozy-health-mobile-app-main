import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  String? _message;
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
    try {
      final response = await ApiClient().get('/student-verification');
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      final data = response.data as Map;
      setState(() {
        _enabled = data['enabled'] == true;
        _application = data['application'] == null
            ? null
            : Map<String, dynamic>.from(data['application'] as Map);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Student review is currently unavailable.');
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
            'Current enrolment is reviewed by our team. Use a dated enrolment letter or student document. Cover unrelated details; do not upload government ID. Approval lasts up to 12 months and must be renewed.',
          ),
          if (_application != null)
            Text(
              'Application: ${_application?['status']}\n${_application?['review_note'] ?? ''}\nEligible until: ${_application?['eligible_until'] ?? 'Not approved'}',
            ),
          if (!_enabled) const Text('Student applications are not open yet.'),
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
          if (_application?['id'] is String &&
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
