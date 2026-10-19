import '../../../../core/services/network_status.dart';
import 'dart:async';
import '../../../../core/audio/voice_audio.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/audio/voice_player.dart';
import '../../../../core/audio/voice_recorder_popup.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/response_data.dart';
import 'provider_screen.dart';
import '../widgets/shared_record_card.dart';
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
  StreamSubscription<void>? _account;
  String? _owner;
  bool get _offline => networkOffline.value == true;
  bool get _current => mounted && _owner == LocalDbService().activeUserId;
  Future<void> _loadCache() async {
    final owner = _owner;
    final settings = await LocalDbService().settingsBox();
    if (!_current || owner != _owner) return;
    final cached = settings.get('provider_conversations_v1');
    if (cached is Map) {
      final threads = _maps(cached['threads'] ?? []);
      final selected =
          threads.where((t) => t['id'] == _thread?['id']).firstOrNull ??
          threads.firstOrNull;
      setState(() {
        _threads = threads;
        _thread = selected;
        _messages = _maps(
          (cached['messages'] as Map?)?[selected?['id'].toString()] ?? [],
        );
        _loading = false;
      });
    }
  }

  Future<void> _saveCache() async {
    final owner = _owner;
    final settings = await LocalDbService().settingsBox();
    if (!_current || owner != _owner) return;
    final cached = settings.get('provider_conversations_v1');
    final messages = <String, dynamic>{
      if (cached is Map && cached['messages'] is Map)
        ...Map<String, dynamic>.from(cached['messages'] as Map),
      if (_thread != null)
        _thread!['id'].toString(): _messages.length > 500
            ? _messages.sublist(_messages.length - 500)
            : _messages,
    };
    final allowed = _threads.map((t) => t['id'].toString()).toSet();
    messages.removeWhere((id, _) => !allowed.contains(id));
    await settings.put('provider_conversations_v1', {
      'threads': _threads,
      'messages': messages,
    });
  }

  void _connectionChanged() {
    if (!_current) return;
    setState(() {});
    if (!_offline) _refresh();
  }

  Future<void> _start() async {
    try {
      await _loadCache();
    } catch (_) {
      /* A first visit has no cache. */
    }
    if (_current) await _refresh();
  }

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
    _owner = LocalDbService().activeUserId;
    networkOffline.addListener(_connectionChanged);
    _account = LocalDbService().accountChanges.listen((_) {
      if (!mounted || _owner == LocalDbService().activeUserId) return;
      setState(() {
        _owner = LocalDbService().activeUserId;
        _threads = [];
        _messages = [];
        _thread = null;
        _selected = [];
        _pending = null;
        _draft.clear();
      });
    });
    unawaited(_start());
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
    _account?.cancel();
    networkOffline.removeListener(_connectionChanged);
    WidgetsBinding.instance.removeObserver(this);
    _draft.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_busy || _offline || !_current) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final owner = _owner;
    _busy = true;
    try {
      final threads = _maps(
        responseMap(await _api.get('/provider-conversations'))['data'],
      );
      if (!_current) return;
      if (owner != _owner) return;
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
            query: {if (_messages.isNotEmpty) 'since': _messages.last['id']},
          ),
        );
        if (!_current) return;
        if (owner != _owner) return;
        final incoming = _maps(page['data']);
        setState(() {
          if (_messages.isEmpty) _more = page['has_more'] == true;
          final combined = {
            for (final row in [..._messages, ...incoming]) row['id']: row,
          };
          _messages = combined.values.toList();
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
      if (_current && owner == _owner) setState(() => _loading = false);
      await _saveCache();
      if (_current && owner == _owner) setState(() => _error = null);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Showing saved messages. Connect to refresh.';
        });
      }
    } finally {
      _busy = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _older() async {
    if (_offline || !_current) return;
    final owner = _owner;
    final threadId = _thread?['id'];
    try {
      final page = responseMap(
        await _api.get(
          '$_path/messages',
          query: {'before': _messages.first['id']},
        ),
      );
      if (_current && owner == _owner && threadId == _thread?['id']) {
        setState(() {
          _messages = [..._maps(page['data']), ..._messages];
          _more = page['has_more'] == true;
        });
        await _saveCache();
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load earlier messages.');
    }
  }

  Future<void> _send() async {
    if (_offline ||
        !_current ||
        _sending ||
        (_draft.text.trim().isEmpty && _selected.isEmpty)) {
      return;
    }
    final owner = _owner;
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
      if (!_current || owner != _owner) return;
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

  Future<void> _recordVoice(BuildContext anchor) async {
    if (_offline || !_current) return;
    final threadId = _thread?['id'] as int?;
    if (threadId == null) return;
    final ownerPath = '/provider-conversations/$threadId';
    var clientId = const Uuid().v4();
    final owner = LocalDbService().activeUserId;
    String? attachmentId, recordedPath;
    await showVoiceRecorder(
      anchor,
      journal: false,
      onConfirm: (audio) async {
        if (_offline) throw StateError('Reconnect before sending a message.');
        if (owner != LocalDbService().activeUserId) {
          throw StateError('Account changed');
        }
        if (recordedPath != audio.path) {
          attachmentId = null;
          clientId = const Uuid().v4();
          recordedPath = audio.path;
        }
        attachmentId ??= await VoiceAudio.upload(
          audio: audio,
          clientId: clientId,
          conversationId: threadId,
          api: _api,
        );
        if (owner != LocalDbService().activeUserId) {
          throw StateError('Account changed');
        }
        if (_offline) throw StateError('Reconnect before sending a message.');
        await _api.post(
          '$ownerPath/messages',
          body: {'client_id': clientId, 'audio_attachment_id': attachmentId},
        );
        await _refresh();
      },
    );
  }

  Future<void> _pick(String type) async {
    if (_offline || !_current) return;
    final owner = _owner;
    final threadId = _thread?['id'];
    int page = 1;
    try {
      bool more = true;
      while (more && mounted) {
        final result = responseMap(
          await _api.get('$_path/records', query: {'type': type, 'page': page}),
        );
        if (!mounted ||
            !_current ||
            owner != _owner ||
            threadId != _thread?['id']) {
          return;
        }
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
                      'Select ${_recordCategory(type).toLowerCase()}',
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
                            title: SharedRecordCard(record: r, preview: true),
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

  String _recordCategory(String type) => switch (type) {
    'moods' => 'Mood check-in',
    'journals' => 'Journal summary',
    'quizzes' => 'Assessment result',
    'notes' => 'Care note',
    _ => 'Record',
  };

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
              onPressed: _offline ? null : _manage,
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
                                  if (_offline) {
                                    _loadCache();
                                  } else {
                                    _refresh();
                                  }
                                },
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          _thread!['name'].toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (_offline)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            'You are offline. Saved conversations are available to read. Reconnect to send messages.',
                          ),
                        ),
                      if (_error != null && !_offline)
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
                                      onPressed: _offline ? null : _older,
                                      child: const Text(
                                        'Load earlier messages',
                                      ),
                                    );
                                  }
                                  final m = _messages[_messages.length - 1 - i];
                                  final mine = m['sender'] == 'patient';
                                  final records = _maps(m['records'] ?? []);
                                  return Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.sizeOf(context).width *
                                            (records.isEmpty ? .8 : .94),
                                      ),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: EdgeInsets.all(
                                        records.isEmpty ? 12 : 0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: records.isNotEmpty
                                            ? Colors.transparent
                                            : mine
                                            ? colors.primaryContainer
                                            : colors.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ...records.map(
                                            (r) => SharedRecordCard(record: r),
                                          ),
                                          if (m['audio'] is Map)
                                            VoicePlayer(
                                              key: ValueKey(m['id']),
                                              source:
                                                  '/audio-attachments/${(m['audio'] as Map)['id']}',
                                              duration:
                                                  (m['audio']
                                                          as Map)['duration']
                                                      as int? ??
                                                  0,
                                              api: _api,
                                            ),
                                          if ((m['content'] ?? '')
                                              .toString()
                                              .isNotEmpty)
                                            Text(m['content'].toString()),
                                          const SizedBox(height: 4),
                                          if (records.isEmpty)
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
                                      label: Text(
                                        _recordCategory(r['type'].toString()),
                                      ),
                                      onPressed: () => showDialog<void>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Record to share'),
                                          content: SingleChildScrollView(
                                            child: SharedRecordCard(
                                              record: r,
                                              preview: true,
                                            ),
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
                              enabled:
                                  !_offline &&
                                  !_sending &&
                                  _selected.length < 10,
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
                                          child: Text(_recordCategory(type)),
                                        ),
                                      )
                                      .toList(),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _draft,
                                enabled: !_offline && !_sending,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 5000,
                                decoration: const InputDecoration(
                                  hintText: 'Write a message…',
                                  counterText: '',
                                ),
                              ),
                            ),
                            Builder(
                              builder: (anchor) => IconButton(
                                tooltip: 'Record voice message',
                                icon: const Icon(Icons.mic_none),
                                onPressed: _offline || _sending
                                    ? null
                                    : () => _recordVoice(anchor),
                              ),
                            ),
                            TextButton(
                              onPressed: _offline || _sending ? null : _send,
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
                          .map((r) => SharedRecordCard(record: r)),
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
