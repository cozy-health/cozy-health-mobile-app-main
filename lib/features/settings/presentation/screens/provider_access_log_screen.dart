import 'package:cozy_health/core/widgets/security_blur.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/settings_service.dart';

class ProviderAccessLogScreen extends StatefulWidget {
  const ProviderAccessLogScreen({super.key, this.settingsService});

  final SettingsService? settingsService;

  @override
  State<ProviderAccessLogScreen> createState() =>
      _ProviderAccessLogScreenState();
}

class _ProviderAccessLogScreenState extends State<ProviderAccessLogScreen> {
  late final SettingsService _service;
  final List<Map<String, dynamic>> _events = [];
  bool _loading = false;
  String? _error;
  int? _nextPage;

  @override
  void initState() {
    super.initState();
    _service = widget.settingsService ?? SettingsService();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    final page = more ? _nextPage : 1;
    if (page == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.getProviderAccessLog(page: page);
      final data = response['data'];
      if (data is! List) throw const FormatException('Missing access log page');
      final events = data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        if (!more) _events.clear();
        _events.addAll(events);
        final lastPage = (response['last_page'] as num?)?.toInt() ?? 1;
        _nextPage = page < lastPage ? page + 1 : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load provider access log.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _description(Map<String, dynamic> event) {
    final resource = switch (event['resource_type']) {
      'client' => 'your profile',
      'mood' => 'your mood entries',
      'journal' => 'your journal summaries',
      'quiz' => 'your quiz results',
      'note' => 'provider notes',
      'consent' => 'your sharing choices',
      'assignment' => 'your resource assignments',
      _ => 'your shared data',
    };
    return switch (event['action']) {
      'list' || 'view' => 'Viewed $resource',
      'create' => 'Added $resource',
      'delete' => 'Deleted $resource',
      'consent_updated' => 'Sharing choices updated',
      'revoked' => 'Provider access revoked',
      'link_attached' => 'Provider accepted your invitation',
      _ => 'Accessed $resource',
    };
  }

  Widget _event(Map<String, dynamic> event) {
    final provider = event['provider'] as Map? ?? {};
    final timestamp = DateTime.tryParse(event['created_at']?.toString() ?? '');
    final practice = provider['practice']?.toString();
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(provider['name']?.toString() ?? 'Provider'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (practice != null && practice.isNotEmpty) Text(practice),
          Text(_description(event)),
          Text(
            timestamp == null
                ? 'Time unavailable'
                : DateFormat('MMM d, y • h:mm a').format(timestamp.toLocal()),
          ),
        ],
      ),
      isThreeLine: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildProtected(context));

  Widget _buildProtected(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Access Log')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              if (_loading && _events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _loading ? null : _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              if (!_loading && _error == null && _events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No provider has accessed your data yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (final event in _events) _event(event),
              if (_nextPage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: Text(_loading ? 'Loading...' : 'Load more'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
