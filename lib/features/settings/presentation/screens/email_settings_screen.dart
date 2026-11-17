import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/local_db_service.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});
  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _status;
  Future<void> _request(bool verify) async {
    if (_busy) return;
    if (verify && !RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _status = 'Enter the six-digit code from your email.');
      return;
    }
    setState(() => _busy = true);
    try {
      final response = await ApiClient().post(
        verify
            ? '/auth/email-verification/verify'
            : '/auth/email-verification/resend',
        data: verify ? {'code': _code.text.trim()} : null,
      );
      if (mounted) {
        setState(
          () => _status =
              response.data['message']?.toString() ?? 'Request accepted.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status =
              'Could not complete verification. Check the code or request a new one and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Email verification')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          LocalDbService().getUserProfile()?.email ??
              'Sign in to view your email.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Verification is for your registered email. Changing your email address is not available here yet.',
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _request(false),
          child: const Text('Send verification code'),
        ),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Verification code'),
        ),
        FilledButton(
          onPressed: _busy ? null : () => _request(true),
          child: const Text('Verify registered email'),
        ),
        if (_status != null) Text(_status!),
      ],
    ),
  );
}
