import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/settings_service.dart';

class ProviderResourcesScreen extends StatefulWidget {
  const ProviderResourcesScreen({
    super.key,
    this.settingsService,
    this.embedded = false,
  });
  final SettingsService? settingsService;
  final bool embedded;

  @override
  State<ProviderResourcesScreen> createState() =>
      _ProviderResourcesScreenState();
}

class _ProviderResourcesScreenState extends State<ProviderResourcesScreen> {
  late final SettingsService _service;
  final List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  int _page = 0;
  int _lastPage = 1;
  String? _updating;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.settingsService ?? SettingsService();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = more ? _page + 1 : 1;
      final response = await _service.getProviderResources(page: page);
      if (!mounted) return;
      setState(() {
        if (!more) _items.clear();
        _items.addAll(
          (response['data'] as List? ?? []).whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ),
        );
        _page = page;
        _lastPage = (response['last_page'] as num?)?.toInt() ?? page;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load provider resources.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(Map<String, dynamic> item, String status) async {
    final id = item['id'].toString();
    setState(() {
      _updating = id;
      _error = null;
    });
    try {
      final response = await _service.updateProviderResource(
        assignmentId: id,
        status: status,
      );
      if (!mounted) return;
      final updated = response['assignment'] as Map<String, dynamic>;
      setState(() {
        final index = _items.indexWhere(
          (entry) => entry['id'].toString() == id,
        );
        if (index >= 0) _items[index] = updated;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to update this resource. Its status has not changed.',
        );
      }
    } finally {
      if (mounted) setState(() => _updating = null);
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    try {
      if (uri == null ||
          !['http', 'https'].contains(uri.scheme) ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Cannot open resource');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to open this resource.');
    }
  }

  Widget _card(Map<String, dynamic> item) {
    final resource = item['resource'] as Map? ?? {};
    final provider = item['provider'] as Map? ?? {};
    final status = item['status']?.toString() ?? 'assigned';
    final url = resource['url']?.toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resource['title']?.toString() ?? 'Resource',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('From ${provider['name'] ?? 'your provider'}'),
            if (provider['practice'] != null)
              Text(provider['practice'].toString()),
            Text(
              [
                resource['type']?.toString(),
                if (resource['duration_minutes'] != null)
                  '${resource['duration_minutes']} min',
              ].whereType<String>().join(' · '),
            ),
            if (resource['description'] != null)
              Text(resource['description'].toString()),
            if (item['notes'] != null)
              Text('Provider guidance: ${item['notes']}'),
            Text(
              {
                    'assigned': 'Assigned',
                    'completed': 'Completed',
                    'declined': 'Declined',
                  }[status] ??
                  status,
            ),
            if (url != null && url.isNotEmpty)
              TextButton(
                onPressed: () => _open(url),
                child: const Text('Open resource'),
              ),
            if (status == 'assigned')
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: _updating != null
                        ? null
                        : () => _update(item, 'completed'),
                    child: const Text('Mark complete'),
                  ),
                  TextButton(
                    onPressed: _updating != null
                        ? null
                        : () => _update(item, 'declined'),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            if (_updating == item['id'].toString())
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (_error != null) ...[
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(
          onPressed: _loading || _updating != null ? null : () => _load(),
          child: const Text('Retry'),
        ),
      ],
      if (_loading && _items.isEmpty)
        const Center(child: CircularProgressIndicator()),
      if (!_loading && _error == null && _items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('Resources assigned by your provider will appear here.'),
        ),
      ..._items.map(_card),
      if (_page < _lastPage && _items.isNotEmpty)
        TextButton(
          onPressed: _loading || _updating != null
              ? null
              : () => _load(more: true),
          child: Text(_loading ? 'Loading...' : 'Load more'),
        ),
      if (widget.embedded)
        TextButton(
          onPressed: _loading || _updating != null ? null : () => _load(),
          child: const Text('Refresh resources'),
        ),
    ];
    if (widget.embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Resources')),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!_loading && _updating == null) await _load();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: children,
        ),
      ),
    );
  }
}
