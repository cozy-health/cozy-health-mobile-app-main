import '../../../journal/presentation/widgets/journal_share_flow.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/plan_access_prompt.dart';
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
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../widgets/provider_record_picker.dart';

class ProviderHubScreen extends StatefulWidget {
  const ProviderHubScreen({super.key, this.apiClient, this.settingsService});
  final ApiClient? apiClient;
  final SettingsService? settingsService;
  @override
  State<ProviderHubScreen> createState() => _ProviderHubScreenState();
}

class _ProviderHubScreenState extends State<ProviderHubScreen>
    with WidgetsBindingObserver {
  late final ApiClient _api;
  late final SettingsService _settings;
  final _draft = TextEditingController();
  final _scopeChanges = ValueNotifier<int>(0);
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
  String? _error, _sendError, _recordError;
  Map<String, dynamic>? _connection;
  int _tab = 0, _requestSerial = 0;
  String get _path => '/provider-conversations/${_thread!['id']}';
  List<Map<String, dynamic>> _maps(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient.instance;
    _settings = widget.settingsService ?? SettingsService(apiClient: _api);
    WidgetsBinding.instance.addObserver(this);
    _owner = LocalDbService().activeUserId;
    _draft.addListener(_draftChanged);
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
        _requestSerial++;
        _busy = false;
        _loading = true;
        _sending = false;
        _more = false;
        _error = _sendError = _recordError = null;
        _connection = null;
      });
      _scopeChanges.value++;
      unawaited(_start());
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
    _scopeChanges.dispose();
    super.dispose();
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (_busy || !_current) return;
    if (_offline) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final owner = _owner;
    final request = ++_requestSerial;
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
        _sendError = _recordError = null;
        _more = false;
        _draft.clear();
        _scopeChanges.value++;
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
      await _saveCache();
      if (_current && owner == _owner) setState(() => _error = null);
      if (_current && owner == _owner && thread == null) {
        final connection = await _settings.getProvider();
        if (_current && owner == _owner) {
          setState(() => _connection = connection);
        }
      }
    } catch (_) {
      if (_current && owner == _owner && request == _requestSerial) {
        setState(() {
          _error = _messages.isEmpty
              ? 'Unable to load your provider. Please try again.'
              : 'Messages may be out of date. Please refresh.';
        });
      }
    } finally {
      if (mounted && owner == _owner && request == _requestSerial) {
        setState(() {
          _busy = false;
          _loading = false;
        });
      }
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
      if (_current && owner == _owner && threadId == _thread?['id']) {
        setState(() => _error = 'Unable to load earlier messages.');
      }
    }
  }

  Future<void> _send() async {
    if (!await ensurePlanAccess(context, 'provider_chat') || !mounted) return;
    if (_offline ||
        !_current ||
        _sending ||
        (_draft.text.trim().isEmpty && _selected.isEmpty)) {
      return;
    }
    final owner = _owner;
    final threadId = _thread?['id'];
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
      _sendError = null;
    });
    try {
      await _api.post('$_path/messages', body: _pending);
      if (!_current || owner != _owner || threadId != _thread?['id']) return;
      setState(() {
        _pending = null;
        _draft.clear();
        _selected = [];
      });
      await _refresh();
    } catch (_) {
      if (_current && owner == _owner && threadId == _thread?['id']) {
        setState(
          () => _sendError =
              'Message was not confirmed. Tap Retry send to try again.',
        );
      }
    } finally {
      if (_current && owner == _owner && threadId == _thread?['id']) {
        setState(() => _sending = false);
      }
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
        if (owner != LocalDbService().activeUserId ||
            threadId != _thread?['id']) {
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
        if (owner != LocalDbService().activeUserId ||
            threadId != _thread?['id']) {
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
    if (_offline || !_current || _selected.length >= 10) return;
    final owner = _owner, id = _thread?['id'];
    final choice = await showWellnessSheet<Map<String, dynamic>>(
      context: context,
      builder: (_) => ProviderRecordPicker(
        api: _api,
        path: _path,
        type: type,
        title: _recordCategory(type).toLowerCase(),
        isCurrent: () => _current && owner == _owner && id == _thread?['id'],
        selected: List.of(_selected),
        scopeChanges: _scopeChanges,
      ),
    );
    if (!_current ||
        owner != _owner ||
        id != _thread?['id'] ||
        choice == null) {
      return;
    }
    if (_selected.length < 10 &&
        !_selected.any(
          (r) => r['id'] == choice['id'] && r['type'] == choice['type'],
        )) {
      setState(() => _selected.add(choice));
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
        builder: (_) => ProviderScreen(settingsService: _settings),
      ),
    );
    if (mounted) _refresh();
  }

  Widget _identityPanel({
    required String label,
    required Widget child,
    VoidCallback? onPressed,
  }) {
    return _threads.length > 1
        ? AppPressable(label: label, onPressed: onPressed, child: child)
        : child;
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final compact = box.maxHeight < 400;
            final name = _thread?['name']?.toString() ?? 'Your provider';
            final large = MediaQuery.textScalerOf(context).scale(w.label) > 21;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    w.page,
                    compact ? 0 : w.small,
                    w.page,
                    compact ? 0 : w.contentGap,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          compact
                              ? name
                              : large
                              ? 'Provider'
                              : 'Your provider',
                          style: compact
                              ? t.textTheme.titleMedium
                              : t.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Connection and sharing permissions',
                        onPressed: _offline ? null : _manage,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                ),
                if (_thread != null && !compact)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: w.page),
                    child: _identityPanel(
                      label: _threads.length > 1
                          ? 'Choose provider, $name'
                          : name,
                      onPressed: _threads.length > 1 && !_sending && !_busy
                          ? _chooseProvider
                          : null,
                      child: WellnessPanel(
                        child: Row(
                          children: [
                            Container(
                              width: w.touch,
                              height: w.touch,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: w.accentPanel(c),
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(w.small),
                              child: ExcludeSemantics(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _initials(name),
                                    style: t.textTheme.titleMedium,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: w.contentGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: t.textTheme.titleMedium),
                                  Text(
                                    large ? 'Connected' : 'Connected provider',
                                    style: t.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            if (_threads.length > 1)
                              const Icon(Icons.unfold_more_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_thread != null && !compact)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      w.page,
                      w.contentGap,
                      w.page,
                      w.contentGap,
                    ),
                    child: WellnessSegments(
                      labels: const ['Messages', 'Shared', 'Resources'],
                      selected: _tab,
                      onSelected: (i) => setState(() => _tab = i),
                      keyPrefix: 'provider-tab',
                    ),
                  ),
                Expanded(
                  child: _loading && _threads.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _thread == null
                      ? _connectionState()
                      : _tab == 1
                      ? _history()
                      : _tab == 2
                      ? ListView(
                          padding: EdgeInsets.all(w.page),
                          children: [
                            ProviderResourcesScreen(
                              key: ValueKey('$_owner-${_thread!['id']}'),
                              embedded: true,
                              settingsService: _settings,
                            ),
                          ],
                        )
                      : _conversation(),
                ),
                if (_thread != null && _tab == 0) _composer(compact),
              ],
            );
          },
        ),
      ),
    );
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s.characters.first.toUpperCase())
      .join();

  Widget _connectionState() {
    final w = context.cozyColors.wellness, t = Theme.of(context);
    final pending = (_connection?['provider'] as Map?)?['status'] == 'pending';
    final linked = _connection?['has_provider'] == true;
    final title = _error != null
        ? 'Connection unavailable'
        : pending
        ? 'Invitation pending'
        : linked
        ? 'Your provider is connected'
        : 'Care, connected.';
    return ListView(
      padding: EdgeInsets.all(w.page),
      children: [
        WellnessPanel(
          tinted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.handshake_outlined, size: 40),
              SizedBox(height: w.gap),
              Text(title, style: t.textTheme.headlineSmall),
              SizedBox(height: w.small),
              Text(
                _error ??
                    (pending
                        ? 'Review your invitation to check its status or request a new code.'
                        : linked
                        ? 'Your connection is active. Refresh to load your conversation.'
                        : 'Connect with your provider to send messages and share the records you choose.'),
              ),
              SizedBox(height: w.sectionSpacing),
              WellnessAction(
                label: _error != null || linked
                    ? 'Refresh'
                    : pending
                    ? 'Review invitation'
                    : 'Connect provider',
                filled: true,
                onPressed: _offline
                    ? null
                    : _error != null || linked
                    ? _refresh
                    : _manage,
              ),
            ],
          ),
        ),
        SizedBox(height: w.sectionSpacing),
        const Text('You choose what to share'),
        SizedBox(height: w.small),
        const Text(
          'Connecting a provider does not automatically share your mood records or journal entries.',
        ),
        if (_offline) ...[
          SizedBox(height: w.gap),
          const Text('You are offline. Reconnect to manage your connection.'),
        ],
      ],
    );
  }

  Future<void> _chooseProvider() async {
    final owner = _owner;
    final id = await showWellnessSheet<int>(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: _scopeChanges,
        builder: (context, _) => WellnessSheet(
          title: 'Choose a provider',
          children: [
            const Text(
              'Messages and shared records belong to the selected conversation.',
            ),
            SizedBox(height: context.cozyColors.wellness.gap),
            if (!_current || owner != _owner)
              const Text(
                'The account changed. Close this chooser and reopen it.',
              )
            else
              for (final thread in _threads)
                WellnessSheetOption(
                  label: thread['name'].toString(),
                  icon: Icons.person_outline_rounded,
                  selected: thread['id'] == _thread?['id'],
                  onPressed: () => Navigator.pop(context, thread['id']),
                ),
            WellnessAction(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (!_current || owner != _owner || id == null || _sending || _busy) return;
    final chosen = _threads.where((t) => t['id'] == id).firstOrNull;
    if (chosen == null || chosen['id'] == _thread?['id']) return;
    setState(() {
      _thread = chosen;
      _messages = [];
      _selected = [];
      _pending = null;
      _sendError = _recordError = _error = null;
      _draft.clear();
      _more = false;
      _scopeChanges.value++;
    });
    if (_offline) {
      await _loadCache();
    } else {
      await _refresh();
    }
  }

  Widget _notice(String text, {VoidCallback? retry, String label = 'Retry'}) =>
      Padding(
        padding: EdgeInsets.only(
          bottom: context.cozyColors.wellness.contentGap,
        ),
        child: WellnessPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(liveRegion: true, child: Text(text)),
              if (retry != null) WellnessAction(label: label, onPressed: retry),
            ],
          ),
        ),
      );

  Widget _conversation() {
    final w = context.cozyColors.wellness, t = Theme.of(context);
    final children = <Widget>[
      if (_more)
        WellnessAction(
          label: 'Load earlier messages',
          onPressed: _offline || _busy ? null : _older,
        ),
      if (_offline)
        _notice(
          'You are offline. Saved conversations are available to read. Reconnect to send messages.',
        ),
      if (_error != null && !_offline)
        _notice(_error!, retry: _busy ? null : _refresh),
      if (_messages.isEmpty)
        WellnessPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Start a conversation', style: t.textTheme.titleMedium),
              SizedBox(height: w.small),
              const Text(
                'Send a message or share a check-in with your connected provider.',
              ),
            ],
          ),
        ),
    ];
    DateTime? last;
    for (final m in _messages) {
      final records = _maps(m['records'] ?? []);
      final date = DateTime.tryParse('${m['created_at']}')?.toLocal();
      // Shared record content intentionally exposes no timestamps or IDs.
      if (records.isEmpty &&
          date != null &&
          (last == null ||
              date.year != last.year ||
              date.month != last.month ||
              date.day != last.day)) {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: w.contentGap),
            child: Center(
              child: Text(
                DateFormat.yMMMd().format(date),
                style: t.textTheme.bodySmall,
              ),
            ),
          ),
        );
        last = date;
      }
      children.add(_message(m));
    }
    if (_recordError != null) {
      children.add(
        _notice(
          _recordError!,
          retry: () => setState(() => _recordError = null),
          label: 'Dismiss',
        ),
      );
    }
    if (_sendError != null) {
      children.add(
        _notice(
          _sendError!,
          retry: _offline || _sending ? null : _send,
          label: 'Retry send',
        ),
      );
    }
    if (_selected.isNotEmpty) children.add(_selectedRecords());
    return Align(
      alignment: Alignment.topCenter,
      child: ListView(
        shrinkWrap: true,
        reverse: true,
        padding: EdgeInsets.symmetric(horizontal: w.page, vertical: w.small),
        children: children.reversed.toList(),
      ),
    );
  }

  Widget _message(Map<String, dynamic> m) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    final mine = m['sender'] == 'patient', records = _maps(m['records'] ?? []);
    final date = DateTime.tryParse('${m['created_at']}')?.toLocal();
    return Padding(
      padding: EdgeInsets.only(bottom: w.contentGap),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: records.isEmpty ? 0.88 : 1,
          child: Column(
            crossAxisAlignment: mine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(records.isEmpty ? w.contentGap : 0),
                decoration: BoxDecoration(
                  color: records.isEmpty
                      ? (mine ? w.accentPanel(c) : c.surface)
                      : Colors.transparent,
                  border: records.isEmpty
                      ? Border.all(color: c.outlineVariant)
                      : null,
                  borderRadius: BorderRadius.circular(w.tileRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...records.map(
                      (r) => r['type'] == 'journal_shares'
                          ? WellnessAction(
                              label: 'Review shared journal copy',
                              icon: Icons.menu_book_outlined,
                              onPressed: _offline
                                  ? null
                                  : () => showSharedJournalCopy(
                                      context,
                                      linkId: _thread!['id'].toString(),
                                      shareId: r['id'].toString(),
                                    ),
                            )
                          : SharedRecordCard(record: r),
                    ),
                    if (m['audio'] is Map)
                      VoicePlayer(
                        key: ValueKey(m['id']),
                        source:
                            '/audio-attachments/${(m['audio'] as Map)['id']}',
                        duration: (m['audio'] as Map)['duration'] as int? ?? 0,
                        api: _api,
                      ),
                    if ((m['content'] ?? '').toString().isNotEmpty)
                      Text(
                        m['content'].toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: c.onSurface,
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              if (records.isEmpty && date != null) ...[
                SizedBox(height: w.tight),
                Text(
                  '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}${mine ? ' · Sent' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _history() {
    final w = context.cozyColors.wellness,
        records = _messages.expand((m) => _maps(m['records'] ?? [])).toList();
    return ListView(
      padding: EdgeInsets.all(w.page),
      children: [
        Text('Shared history', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: w.tight),
        const Text(
          'Only records you choose appear here. Sharing permissions control provider access.',
        ),
        SizedBox(height: w.contentGap),
        WellnessAction(
          label: 'Manage sharing',
          onPressed: _offline ? null : _manage,
        ),
        SizedBox(height: w.contentGap),
        if (records.isEmpty)
          const WellnessPanel(
            child: Text(
              'No records shared in this conversation yet. Choose Share records in Messages to get started.',
            ),
          ),
        ...records.map((r) => SharedRecordCard(record: r)),
        if (_more)
          WellnessAction(
            label: 'Load earlier shared records',
            onPressed: _offline || _busy ? null : _older,
          ),
      ],
    );
  }

  String _recordTitle(Map<String, dynamic> r) {
    final data = r['data'] as Map? ?? {};
    return '${_recordCategory(r['type'].toString())}${data['title'] != null
        ? ' · ${data['title']}'
        : data['mood'] != null
        ? ' · ${data['mood']}'
        : ''}';
  }

  Widget _selectedRecords() {
    final w = context.cozyColors.wellness;
    return WellnessPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_selected.length} of 10 records selected'),
          for (final r in _selected)
            Row(
              children: [
                Expanded(
                  child: AppPressable(
                    label: 'Preview ${_recordTitle(r)}',
                    onPressed: () {
                      final owner = _owner, threadId = _thread?['id'];
                      showWellnessSheet<void>(
                        context: context,
                        builder: (context) => ListenableBuilder(
                          listenable: _scopeChanges,
                          builder: (context, _) => WellnessSheet(
                            title: 'Record preview',
                            children: [
                              if (_current &&
                                  owner == _owner &&
                                  threadId == _thread?['id']) ...[
                                const Text(
                                  'Check what your provider will receive before sending.',
                                ),
                                SizedBox(height: w.gap),
                                SharedRecordCard(record: r, preview: true),
                              ] else
                                const Text(
                                  'The account or conversation changed. Close this preview and reopen it.',
                                ),
                              SizedBox(height: w.gap),
                              WellnessAction(
                                label: 'Done',
                                filled: true,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: w.contentGap),
                      child: Text(_recordTitle(r)),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove ${_recordTitle(r)}',
                  onPressed: _sending
                      ? null
                      : () => setState(() => _selected.remove(r)),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _composer(bool compact) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    final enabled = !_offline && !_sending && _current;
    final canSend =
        enabled && (_draft.text.trim().isNotEmpty || _selected.isNotEmpty);
    final label = _sending
        ? 'Sending…'
        : _pending != null
        ? 'Retry send'
        : 'Send';
    final input = TextField(
      key: const ValueKey('provider-message-input'),
      controller: _draft,
      enabled: enabled,
      minLines: 1,
      maxLines: compact ? 1 : 4,
      maxLength: 5000,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Write a message…',
        counterText: '',
        contentPadding: EdgeInsets.all(compact ? w.small : w.contentGap),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(w.tileRadius),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(w.tileRadius),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
      ),
    );
    final share = PopupMenuButton<String>(
      enabled: enabled && _selected.length < 10,
      tooltip: 'Share a record',
      icon: const Icon(Icons.add_rounded),
      onSelected: _pick,
      itemBuilder: (_) => ['moods', 'journals', 'quizzes', 'notes']
          .map(
            (type) => PopupMenuItem(
              value: type,
              enabled: (_thread!['consent_flags'] as Map? ?? {})[type] == true,
              child: Text(_recordCategory(type)),
            ),
          )
          .toList(),
    );
    final voice = Builder(
      builder: (anchor) => IconButton(
        tooltip: 'Record voice message',
        icon: const Icon(Icons.mic_none_rounded),
        onPressed: enabled ? () => _recordVoice(anchor) : null,
      ),
    );
    final send = Tooltip(
      message: label,
      child: AppPressable(
        key: const ValueKey('provider-send'),
        label: label,
        onPressed: canSend ? _send : null,
        child: Container(
          width: w.touch,
          height: w.touch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: canSend ? c.primary : c.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(w.tileRadius),
          ),
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.arrow_upward_rounded,
                  color: canSend ? c.onPrimary : c.onSurfaceVariant,
                ),
        ),
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w.page, vertical: w.small),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.outlineVariant)),
      ),
      child: compact
          ? Row(
              children: [
                Expanded(child: input),
                SizedBox(width: w.small),
                share,
                voice,
                send,
              ],
            )
          : Column(
              children: [
                input,
                SizedBox(height: w.small),
                Row(
                  children: [
                    share,
                    if (_selected.isNotEmpty) Text('${_selected.length}/10'),
                    const Spacer(),
                    voice,
                    SizedBox(width: w.small),
                    send,
                  ],
                ),
              ],
            ),
    );
  }
}
