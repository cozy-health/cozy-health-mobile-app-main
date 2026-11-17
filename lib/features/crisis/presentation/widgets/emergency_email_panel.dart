import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/widgets/app_button.dart';

class EmergencyEmailPanel extends StatefulWidget {
  const EmergencyEmailPanel({super.key});
  @override
  State<EmergencyEmailPanel> createState() => _EmergencyEmailPanelState();
}

class _EmergencyEmailPanelState extends State<EmergencyEmailPanel> {
  final _email = TextEditingController();
  final _owner = LocalDbService().activeUserId;
  bool _enabled = false,
      _confirmed = false,
      _acknowledged = false,
      _busy = false;
  String? _message, _requestId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await ApiClient().get('/emergency-email');
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      final data = response.data as Map, contact = data['contact'];
      setState(() {
        _enabled = data['enabled'] == true;
        _confirmed = contact is Map && contact['confirmed_at'] != null;
        if (contact is Map) _email.text = contact['email'] as String? ?? '';
        final alert = data['latest_alert'];
        if (alert is Map) {
          _message =
              'Latest email request: ${alert['status']}. Delivery is not confirmed.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _message = 'Email is unavailable. Use the message/call options.',
        );
      }
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || _owner != LocalDbService().activeUserId) return;
    setState(() => _busy = true);
    try {
      await action();
    } on DioException catch (error) {
      if (mounted) {
        setState(
          () => _message = error.response?.data is Map
              ? (error.response?.data['message'] as String? ??
                    'Email request failed. Use message/call.')
              : 'Email request could not be confirmed. Use message/call.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Email request could not be confirmed. Use message/call.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Emergency-contact email',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      const Text(
        'Email can be delayed, fail, or reach a sending limit. It does not contact emergency services. Message/call options remain available above.',
      ),
      if (!_enabled) const Text('Automatic email is not activated yet.'),
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Emergency-contact email'),
      ),
      CheckboxListTile(
        value: _acknowledged,
        onChanged: !_enabled || _busy
            ? null
            : (value) => setState(() => _acknowledged = value == true),
        title: const Text(
          'I authorize a confirmation request to this person. They must agree before alerts can be sent.',
        ),
      ),
      AppButton(
        key: const ValueKey('emergency-email-confirmation'),
        text: 'Request contact confirmation',
        isOutlined: true,
        onPressed: !_enabled || !_acknowledged || _busy
            ? null
            : () => _run(() async {
                await ApiClient().post(
                  '/emergency-email',
                  data: {'email': _email.text.trim(), 'acknowledged': true},
                );
                if (mounted) {
                  setState(() {
                    _confirmed = false;
                    _message =
                        'Confirmation requested. Ask your contact to confirm, then check status.';
                  });
                }
              }),
      ),
      const SizedBox(height: 8),
      AppButton(
        key: const ValueKey('emergency-email-alert'),
        text: 'Request support by email',
        isLoading: _busy,
        onPressed: !_enabled || !_confirmed
            ? null
            : () => _run(() async {
                _requestId ??= const Uuid().v4();
                final response = await ApiClient().post(
                  '/emergency-email/alerts',
                  data: {'request_id': _requestId},
                );
                if (mounted && _owner == LocalDbService().activeUserId) {
                  setState(() {
                    _message =
                        'Email request: ${response.data['alert']['status']}. Delivery is not confirmed. Use message/call if you need immediate help.';
                    _requestId = null;
                  });
                }
              }),
      ),
      const SizedBox(height: 8),
      AppButton(
        key: const ValueKey('emergency-email-status'),
        text: 'Check contact and email status',
        isOutlined: true,
        onPressed: _busy ? null : _load,
      ),
      const SizedBox(height: 8),
      AppButton(
        key: const ValueKey('emergency-email-remove'),
        text: 'Remove email contact',
        isOutlined: true,
        onPressed: !_enabled || _busy
            ? null
            : () => _run(() async {
                await ApiClient().delete('/emergency-email');
                if (mounted) {
                  setState(() {
                    _confirmed = false;
                    _email.clear();
                    _message = 'Email contact removed.';
                  });
                }
              }),
      ),
      if (_message != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Semantics(liveRegion: true, child: Text(_message!)),
        ),
      const Divider(height: 32),
    ],
  );
}
