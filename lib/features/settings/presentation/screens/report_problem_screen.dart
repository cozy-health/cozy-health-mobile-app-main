import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/widgets/security_blur.dart';
import 'package:uuid/uuid.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key, this.feedback = false});
  final bool feedback;
  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _message = TextEditingController();
  final _owner = LocalDbService().activeUserId;
  bool _busy = false;
  String? _error;
  String _category = 'General';
  String _requestId = const Uuid().v4();
  String? _lastPayload;
  Future<void> _submit() async {
    if (_owner != LocalDbService().activeUserId ||
        _busy ||
        _message.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final payload = '$_category:${_message.text.trim()}';
    if (_lastPayload != payload) {
      _requestId = const Uuid().v4();
      _lastPayload = payload;
    }
    try {
      await ApiClient().post(
        '/support/reports',
        data: {
          'subject':
              '${widget.feedback ? 'Feedback' : 'Problem report'}: $_category',
          'message': _message.text.trim(),
          'request_id': _requestId,
        },
      );
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      AppSnackbar.show(
        context,
        const SnackBar(content: Text('Your report was received. Thank you.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not submit. Your message is still here; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildReport(context));

  Widget _buildReport(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.feedback ? 'Share feedback' : 'Report a problem'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final name in ['General', 'Bug', 'Feature request', 'Account'])
              DropdownMenuItem(value: name, child: Text(name)),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() => _category = value ?? 'General'),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _message,
          maxLength: 10000,
          minLines: 6,
          maxLines: 14,
          decoration: const InputDecoration(
            labelText: 'Your message',
            alignLabelWithHint: true,
          ),
        ),
        const Text(
          'Screenshot attachments are not available yet. Please describe the screen and what happened.',
        ),
        const SizedBox(height: 16),
        if (_error != null) Text(_error!),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Submitting…' : 'Submit'),
        ),
      ],
    ),
  );
}
