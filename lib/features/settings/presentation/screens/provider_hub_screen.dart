import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/response_data.dart';
import 'provider_screen.dart';
import '../../data/settings_service.dart';
import 'provider_resources_screen.dart';

class ProviderHubScreen extends StatefulWidget {
  const ProviderHubScreen({super.key, this.apiClient});
  final ApiClient? apiClient;
  @override
  State<ProviderHubScreen> createState() => _ProviderHubScreenState();
}

class _ProviderHubScreenState extends State<ProviderHubScreen>
    with WidgetsBindingObserver {
  late final ApiClient _api;
  final _draft = TextEditingController();
  Timer? _timer;
  List<Map<String, dynamic>> _threads = [], _messages = [], _selected = [];
  Map<String, dynamic>? _thread, _pending;
  bool _loading = true,
      _busy = false,
      _sending = false,
      _more = false,
      _active = true;
  String? _error;
  String get _path => '/provider-conversations/${_thread!['id']}';
  List<Map<String, dynamic>> _maps(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient.instance;
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_active) _refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _draft.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      final threads = _maps(
        responseMap(await _api.get('/provider-conversations'))['data'],
      );
      if (!mounted) return;
      final oldId = _thread?['id'];
      final thread =
          threads.where((t) => t['id'] == oldId).firstOrNull ??
          threads.firstOrNull;
      if (oldId != thread?['id']) {
        _messages = [];
        _selected = [];
        _pending = null;
        _more = false;
        _draft.clear();
      }
      setState(() {
        _threads = threads;
        _thread = thread;
      });
      if (thread != null) {
        final page = responseMap(
          await _api.get(
            '$_path/messages',
            query: {if (_messages.isNotEmpty) 'since': _messages.first['id']},
          ),
        );
        if (!mounted) return;
        final incoming = _maps(page['data']);
        setState(() {
          _messages = incoming;
          _more = page['has_more'] == true;
        });
        if (incoming.isNotEmpty) {
          await _api.post(
            '$_path/read',
            body: {'through': incoming.last['id']},
          );
        }
      } else {
        _messages = [];
      }
      if (mounted) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to refresh messages. Please retry.';
          _messages = [];
        });
      }
    } finally {
      _busy = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _older() async {
    try {
      final page = responseMap(
        await _api.get(
          '$_path/messages',
          query: {'before': _messages.first['id']},
        ),
      );
      if (mounted) {
        setState(() {
          _messages = [..._maps(page['data']), ..._messages];
          _more = page['has_more'] == true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load earlier messages.');
    }
  }

  Future<void> _send() async {
    if (_sending || (_draft.text.trim().isEmpty && _selected.isEmpty)) return;
    final payload = {
      'content': _draft.text.trim(),
      'records': _selected
          .map((r) => {'type': r['type'], 'id': r['id']})
          .toList(),
    };
    if (_pending == null ||
        _pending!['content'] != payload['content'] ||
        _pending!['records'].toString() != payload['records'].toString()) {
      _pending = {...payload, 'client_id': const Uuid().v4()};
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _api.post('$_path/messages', body: _pending);
      if (!mounted) return;
      setState(() {
        _pending = null;
        _draft.clear();
        _selected = [];
      });
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Message was not confirmed. Tap Retry send to try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pick(String type) async {
    int page = 1;
    try {
      bool more = true;
      while (more && mounted) {
        final result = responseMap(
          await _api.get('$_path/records', query: {'type': type, 'page': page}),
        );
        if (!mounted) return;
        final rows = _maps(result['data']);
        more = (result['current_page'] as int) < (result['last_page'] as int);
        final choice = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select $type',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        if (rows.isEmpty)
                          const ListTile(title: Text('No records available.')),
                        ...rows.map(
                          (r) => ListTile(
                            title: Text(_recordText(r)),
                            onTap: () => Navigator.pop(context, r),
                          ),
                        ),
                        if (more)
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, {'next': true}),
                            child: const Text('Next page'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (choice == null) return;
        if (choice['next'] == true) {
          page++;
          continue;
        }
        if (mounted) {
          setState(() {
            if (_selected.length < 10 &&
                !_selected.any(
                  (r) => r['id'] == choice['id'] && r['type'] == choice['type'],
                )) {
              _selected.add(choice);
            }
          });
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Unable to load records. Check sharing permissions and retry.',
        );
      }
    }
  }

  String _recordText(Map<String, dynamic> r) {
    if (r['unavailable'] == true) {
      return '${r['type']}: Record unavailable or sharing disabled.';
    }
    final data = Map<String, dynamic>.from(r['data'] as Map? ?? {});
    return '${r['type']}\n${data.entries.where((e) => e.value != null).map((e) => '${e.key.replaceAll('_', ' ')}: ${e.value}').join('\n')}';
  }

  Future<void> _manage() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProviderScreen(settingsService: SettingsService(apiClient: _api)),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Provider'),
          actions: [
            IconButton(
              tooltip: 'Connection and sharing permissions',
              onPressed: _manage,
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          ],
          bottom: _thread == null
              ? null
              : const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Messages'),
                    Tab(text: 'Shared history'),
                    Tab(text: 'Resources'),
                  ],
                ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _thread == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ??
                          'Connect your provider to start a conversation.',
                    ),
                    TextButton(
                      onPressed: _manage,
                      child: const Text('Connect provider'),
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  Column(
                    children: [
                      if (_threads.length > 1)
                        DropdownButton<int>(
                          value: _thread!['id'] as int,
                          items: _threads
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t['id'] as int,
                                  child: Text(t['name'].toString()),
                                ),
                              )
                              .toList(),
                          onChanged: _sending || _busy
                              ? null
                              : (id) {
                                  setState(() {
                                    _thread = _threads.firstWhere(
                                      (t) => t['id'] == id,
                                    );
                                    _messages = [];
                                    _selected = [];
                                    _pending = null;
                                    _draft.clear();
                                    _more = false;
                                  });
                                  _refresh();
                                },
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _thread!['name'].toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_error != null)
                        MaterialBanner(
                          content: Text(_error!),
                          actions: [
                            TextButton(
                              onPressed: _refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      Expanded(
                        child: _messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Start a conversation with your provider.',
                                ),
                              )
                            : ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length + (_more ? 1 : 0),
                                itemBuilder: (context, i) {
                                  if (i == _messages.length) {
                                    return TextButton(
                                      onPressed: _older,
                                      child: const Text(
                                        'Load earlier messages',
                                      ),
                                    );
                                  }
                                  final m = _messages[_messages.length - 1 - i];
                                  final mine = m['sender'] == 'patient';
                                  return Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                            .8,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: mine
                                            ? colors.primaryContainer
                                            : colors.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ..._maps(m['records'] ?? []).map(
                                            (r) => Card(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                child: Text(_recordText(r)),
                                              ),
                                            ),
                                          ),
                                          if ((m['content'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(m['content'].toString()),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateTime.tryParse(
                                                      m['created_at']
                                                          .toString(),
                                                    )
                                                    ?.toLocal()
                                                    .toString()
                                                    .substring(0, 16) ??
                                                '',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (_selected.isNotEmpty)
                        SizedBox(
                          height: 72,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: _selected
                                .map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: InputChip(
                                      label: Text('${r['type']} record'),
                                      onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Record to share'),
                                          content: SingleChildScrollView(
                                            child: Text(_recordText(r)),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Close'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onDeleted: _sending
                                          ? null
                                          : () => setState(
                                              () => _selected.remove(r),
                                            ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            PopupMenuButton<String>(
                              enabled: !_sending && _selected.length < 10,
                              tooltip: 'Share a record',
                              icon: const Icon(Icons.add_circle_outline),
                              onSelected: _pick,
                              itemBuilder: (_) =>
                                  ['moods', 'journals', 'quizzes', 'notes']
                                      .map(
                                        (type) => PopupMenuItem(
                                          value: type,
                                          enabled:
                                              (_thread!['consent_flags']
                                                  as Map)[type] ==
                                              true,
                                          child: Text(type),
                                        ),
                                      )
                                      .toList(),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _draft,
                                enabled: !_sending,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 5000,
                                decoration: const InputDecoration(
                                  hintText: 'Write a message…',
                                  counterText: '',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _sending ? null : _send,
                              child: Text(
                                _sending
                                    ? 'Sending…'
                                    : _pending != null
                                    ? 'Retry send'
                                    : 'Send',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Selected records shared in this conversation. Sharing permissions control provider access.',
                      ),
                      TextButton(
                        onPressed: _manage,
                        child: const Text('Manage sharing'),
                      ),
                      ..._messages
                          .expand((m) => _maps(m['records'] ?? []))
                          .map(
                            (r) => Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(_recordText(r)),
                              ),
                            ),
                          ),
                      if (_more)
                        TextButton(
                          onPressed: _older,
                          child: const Text('Load earlier shared records'),
                        ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ProviderResourcesScreen(
                        embedded: true,
                        settingsService: SettingsService(apiClient: _api),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
