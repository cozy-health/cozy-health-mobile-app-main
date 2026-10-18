import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key, this.feedback = false});
  final bool feedback;
  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final _message = TextEditingController();
  bool _busy = false;
  String? _error;
  String _category = 'General';
  Future<void> _submit() async {
    if (_busy || _message.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiClient().post(
        '/support/reports',
        data: {
          'subject':
              '${widget.feedback ? 'Feedback' : 'Problem report'}: $_category',
          'message': _message.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
  Widget build(BuildContext context) => Scaffold(
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
