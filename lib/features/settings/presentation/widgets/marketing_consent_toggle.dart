import 'package:flutter/material.dart';
import '../../../../core/services/consent_service.dart';

class MarketingConsentToggle extends StatefulWidget {
  const MarketingConsentToggle({super.key});
  @override
  State<MarketingConsentToggle> createState() => _MarketingConsentToggleState();
}

class _MarketingConsentToggleState extends State<MarketingConsentToggle> {
  final _service = ConsentService();
  ConsentState? _state;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final value = await _service.load();
      if (mounted) setState(() => _state = value);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load your marketing preference.');
      }
    }
  }

  Future<void> _toggle(bool value) async {
    if (_state == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.marketing(_state!, value);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your choice. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile(
        title: const Text('Marketing emails'),
        subtitle: const Text(
          'Optional news and offers from Cozy. Off unless you opt in.',
        ),
        value: _state?.marketingAllowed ?? false,
        onChanged: _state == null || _busy ? null : _toggle,
      ),
      if (_error != null)
        Row(
          children: [
            Expanded(child: Text(_error!)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
    ],
  );
}
