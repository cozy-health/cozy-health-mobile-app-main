import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/services/network_status.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/settings_service.dart';

class ProviderReplacementPanel extends StatefulWidget {
  const ProviderReplacementPanel({
    super.key,
    required this.originalLinkId,
    required this.state,
    required this.service,
    required this.onChanged,
  });

  final int originalLinkId;
  final Map<String, dynamic> state;
  final SettingsService service;
  final Future<void> Function() onChanged;

  @override
  State<ProviderReplacementPanel> createState() =>
      _ProviderReplacementPanelState();
}

class _ProviderReplacementPanelState extends State<ProviderReplacementPanel> {
  final _email = TextEditingController();
  final _owner = LocalDbService().activeUserId;
  String? _requestId, _requestEmail, _error;
  bool _busy = false;
  bool get _current => mounted && _owner == LocalDbService().activeUserId;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _change({String? cancelId}) async {
    if (!_current || _busy || networkOffline.value == true) return;
    final email = _email.text.trim();
    if (cancelId == null && (email.isEmpty || !email.contains('@'))) {
      setState(() => _error = 'Enter your replacement provider’s email.');
      return;
    }
    if (_requestEmail != email) {
      _requestId = const Uuid().v4();
      _requestEmail = email;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (cancelId != null) {
        await widget.service.cancelProviderReplacement(cancelId);
      } else {
        await widget.service.requestProviderReplacement(
          originalLinkId: widget.originalLinkId,
          providerEmail: email,
          requestId: _requestId ??= const Uuid().v4(),
        );
      }
      if (!_current) return;
      _requestId = null;
      _requestEmail = null;
      await widget.onChanged();
    } on ApiException catch (error) {
      if (_current) setState(() => _error = error.message);
    } catch (_) {
      if (_current) {
        setState(
          () => _error =
              'Unable to update the invitation. Check your connection and retry.',
        );
      }
    } finally {
      if (_current) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    final raw = widget.state['pending'];
    final pending = raw is Map ? raw : null;
    final waiting = pending?['status'] == 'pending';
    final canStart = widget.state['eligible'] == true;
    final disabled = _busy || networkOffline.value == true;
    return Padding(
      padding: EdgeInsets.only(top: w.gap),
      child: WellnessPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose another provider',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: w.small),
            const Text(
              'After seven unanswered days, you can invite another provider. Your current connection stays active until they accept. Sharing starts off with the new provider.',
            ),
            if (_error != null) ...[
              SizedBox(height: w.small),
              Semantics(liveRegion: true, child: Text(_error!)),
            ],
            if (waiting) ...[
              SizedBox(height: w.small),
              Text('Invitation pending: ${pending?['provider_email'] ?? ''}'),
              if (pending?['invitation_code'] is String)
                SelectableText(
                  'Invitation code: ${pending?['invitation_code']}',
                ),
              const Text(
                'A late reply from your current provider will not cancel your choice.',
              ),
              SizedBox(height: w.small),
              WellnessAction(
                key: const ValueKey('cancel-provider-replacement'),
                label: _busy ? 'Updating…' : 'Cancel replacement invitation',
                onPressed: disabled || pending?['request_id'] is! String
                    ? null
                    : () => _change(cancelId: pending!['request_id'] as String),
              ),
            ] else ...[
              if (pending?['status'] == 'expired')
                const Text(
                  'The replacement invitation expired. Your current connection is unchanged.',
                ),
              if (pending?['status'] == 'cancelled')
                const Text(
                  'The replacement invitation was cancelled. Your current connection is unchanged.',
                ),
              if (canStart) ...[
                SizedBox(height: w.small),
                TextField(
                  key: const ValueKey('replacement-provider-email'),
                  controller: _email,
                  enabled: !disabled,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Replacement provider email',
                  ),
                ),
                SizedBox(height: w.small),
                WellnessAction(
                  key: const ValueKey('request-provider-replacement'),
                  label: _busy ? 'Sending…' : 'Invite replacement provider',
                  onPressed: disabled ? null : () => _change(),
                ),
              ] else ...[
                SizedBox(height: w.small),
                const Text(
                  'This option becomes available after 168 hours without a provider reply and requires active Student or Premium access.',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
