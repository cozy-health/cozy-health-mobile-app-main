import '../../../../core/theme/cozy_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/plan_access_prompt.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/api/response_data.dart';
import '../../../../core/models/journal_entry.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';

Future<void> showJournalShareFlow(
  BuildContext context,
  JournalEntry entry, {
  ApiClient? apiClient,
  Future<void> Function()? sync,
}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close journal sharing',
  barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
  pageBuilder: (_, __, ___) =>
      JournalShareFlow(entry: entry, apiClient: apiClient, sync: sync),
);

/// Online-only review. Neither previews nor confirmed copies enter local storage.
class JournalShareFlow extends StatefulWidget {
  const JournalShareFlow({
    super.key,
    required this.entry,
    this.apiClient,
    this.sync,
  });
  final JournalEntry entry;
  final ApiClient? apiClient;
  final Future<void> Function()? sync;
  @override
  State<JournalShareFlow> createState() => _JournalShareFlowState();
}

class _JournalShareFlowState extends State<JournalShareFlow>
    with WidgetsBindingObserver {
  late final _api = widget.apiClient ?? ApiClient.instance;
  final _generation = TokenStorage.generation;
  final _owner = LocalDbService.instance.activeUserId;
  StreamSubscription<void>? _clearing, _session;
  List<Map<String, dynamic>> _providers = [];
  Map<String, dynamic>? _provider, _preview;
  String? _share, _clientId, _error;
  bool _busy = true, _ended = false, _off = false;
  bool get _active =>
      mounted &&
      !_ended &&
      _generation == TokenStorage.generation &&
      _owner == LocalDbService.instance.activeUserId;
  String get _path =>
      '/provider-conversations/${_provider!['id']}/journal-shares';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clearing = TokenStorage.sessionClearing.listen((_) => _end());
    _session = TokenStorage.sessionChanges.listen((_) => _end());
    _load();
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    _preview = null;
    if (mounted) {
      final route = ModalRoute.of(context);
      if (route != null && route.isActive) {
        Navigator.of(context).removeRoute(route);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _end();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearing?.cancel();
    _session?.cancel();
    _preview = null;
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final raw = responseMap(
        await _api.get('/provider-conversations'),
      )['data'];
      if (!_active) return;
      setState(
        () => _providers = (raw as List)
            .whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r))
            .toList(),
      );
    } catch (_) {
      if (_active) {
        setState(
          () => _error =
              'Could not load providers. Check your connection and retry.',
        );
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _review(Map<String, dynamic> provider) async {
    setState(() {
      _provider = provider;
      _preview = null;
      _clientId = null;
      _error = null;
      _off = (provider['consent_flags'] as Map?)?['journals'] != true;
    });
    if (_off) return;
    setState(() => _busy = true);
    try {
      if (widget.sync != null) {
        await widget.sync!();
      } else {
        await LocalDbService.instance.processSyncQueue();
      }
      if (!_active) return;
      final preview = responseMap(
        await _api.get(
          '$_path/preview',
          query: {'journal_id': widget.entry.id},
        ),
      );
      if (!_active) return;
      final data = Map<String, dynamic>.from(
        preview['data'] is Map ? preview['data'] as Map : preview,
      );
      final entry = data['entry'] as Map;
      if (entry['body'] != widget.entry.body ||
          (entry['title'] ?? '') != (widget.entry.title ?? '')) {
        throw StateError('Entry has not synced');
      }
      setState(() {
        _preview = data;
        _clientId = const Uuid().v4();
      });
    } catch (e) {
      if (_active) {
        setState(() {
          _off = e is ApiException && e.statusCode == 403;
          _error = _off
              ? null
              : 'Could not review this entry. Save and sync the written entry, then retry. No entry has been shared by this action.';
        });
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (!await ensurePlanAccess(context, 'journal_share') || !mounted) return;
    if (_busy || _preview == null || _clientId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = responseMap(
        await _api.post(
          _path,
          body: {
            'journal_id': widget.entry.id,
            'expected_revision': _preview!['revision'],
            'client_id': _clientId,
            'confirmed': true,
          },
        ),
      );
      if (!_active) return;
      final data = result['data'] is Map ? result['data'] as Map : result;
      setState(() {
        _share = data['share_id'].toString();
        _preview = null;
      });
    } catch (e) {
      if (_active) {
        setState(() {
          if (e is ApiException && e.statusCode == 409) {
            _preview = null;
            _clientId = null;
            _error =
                'The entry or sharing status changed. Review again before sharing a new copy.';
          } else {
            _error =
                'Could not confirm sharing. Retry uses the same confirmation to avoid sending a duplicate.';
          }
        });
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalid =
        widget.entry.isDraft ||
        widget.entry.type == 'voice' ||
        widget.entry.voiceUrl != null ||
        widget.entry.localVoicePath != null ||
        widget.entry.body.trim().isEmpty;
    final title = invalid
        ? 'Save a written entry first'
        : _share != null
        ? 'Entry shared'
        : _off
        ? 'Journal sharing is off'
        : !_busy && _providers.isEmpty && _error == null
        ? 'Connect a provider first'
        : _preview != null
        ? 'Review before sharing'
        : 'Choose a provider';
    final children = <Widget>[
      if (_busy)
        const LinearProgressIndicator(
          semanticsLabel: 'Loading journal sharing',
        ),
      if (invalid)
        const Text(
          'Only saved written entries can be shared. Audio stays private.',
        )
      else if (_share != null) ...[
        Text(
          'A written copy was shared with ${_provider!['name']}. Later edits stay private.',
        ),
        WellnessAction(
          label: 'View shared copy',
          onPressed: () => showSharedJournalCopy(
            context,
            linkId: _provider!['id'].toString(),
            shareId: _share!,
          ),
        ),
      ] else if (_off) ...[
        const Text(
          'Allow journal sharing with this provider in Provider settings. You will still review and confirm each entry before sending.',
        ),
        WellnessAction(
          label: 'Open provider settings',
          onPressed: () {
            Navigator.pop(context);
            context.push(AppRouter.provider);
          },
        ),
      ] else if (!_busy && _providers.isEmpty && _error == null) ...[
        const Text(
          'Connect a provider before sharing. Connecting will not send anything automatically.',
        ),
        WellnessAction(
          label: 'Open provider settings',
          onPressed: () {
            Navigator.pop(context);
            context.push(AppRouter.provider);
          },
        ),
      ] else if (_preview != null) ...[
        Text('Share with ${_provider!['name']}'),
        Text(
          (_preview!['entry'] as Map)['title']?.toString() ?? '',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SelectableText((_preview!['entry'] as Map)['body'].toString()),
        const Text(
          'Only this written copy will be shared. Audio is excluded. Later edits stay private.',
        ),
        WellnessAction(
          key: const ValueKey('confirm-journal-share'),
          label: 'Share this copy',
          icon: Icons.ios_share_outlined,
          onPressed: _busy ? null : _send,
        ),
      ] else if (!_busy) ...[
        const Text(
          'Choose who should receive this written copy. Nothing is sent until you confirm.',
        ),
        for (final p in _providers)
          WellnessSheetOption(
            label: p['name'].toString(),
            icon: Icons.forum_outlined,
            onPressed: () => _review(p),
          ),
      ],
      if (_error != null) ...[
        Semantics(liveRegion: true, child: Text(_error!)),
        WellnessAction(
          label: 'Retry',
          onPressed: _busy
              ? null
              : _preview != null
              ? _send
              : _provider != null
              ? () => _review(_provider!)
              : _load,
        ),
      ],
    ];
    if (_preview != null) {
      final w = context.cozyColors.wellness;
      return PopScope(
        canPop: !_busy,
        child: Scaffold(
          appBar: AppBar(title: const Text('Review before sharing')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(w.page),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...children,
                  SizedBox(height: w.gap),
                  WellnessAction(
                    label: 'Cancel',
                    onPressed: _busy ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.cozyColors.wellness.radius),
      ),
      child: WellnessSheet(title: title, busy: _busy, children: children),
    );
  }
}

Future<void> showSharedJournalCopy(
  BuildContext context, {
  required String linkId,
  required String shareId,
}) => showWellnessDialog<void>(
  context: context,
  builder: (_) => SharedJournalCopyView(linkId: linkId, shareId: shareId),
);

class SharedJournalCopyView extends StatefulWidget {
  const SharedJournalCopyView({
    super.key,
    required this.linkId,
    required this.shareId,
    this.apiClient,
  });
  final String linkId, shareId;
  final ApiClient? apiClient;
  @override
  State<SharedJournalCopyView> createState() => _SharedJournalCopyViewState();
}

class _SharedJournalCopyViewState extends State<SharedJournalCopyView>
    with WidgetsBindingObserver {
  late final _api = widget.apiClient ?? ApiClient.instance;
  final _generation = TokenStorage.generation;
  StreamSubscription<void>? _clearing, _session;
  Map<String, dynamic>? _copy;
  bool _busy = true, _unavailable = false, _ended = false;
  String get _path =>
      '/provider-conversations/${widget.linkId}/journal-shares/${widget.shareId}';
  bool get _active =>
      mounted && !_ended && _generation == TokenStorage.generation;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clearing = TokenStorage.sessionClearing.listen((_) => _end());
    _session = TokenStorage.sessionChanges.listen((_) => _end());
    _load();
  }

  void _end() {
    _ended = true;
    _copy = null;
    if (mounted) {
      final route = ModalRoute.of(context);
      if (route != null && route.isActive) {
        Navigator.of(context).removeRoute(route);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _end();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clearing?.cancel();
    _session?.cancel();
    _copy = null;
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final r = responseMap(await _api.get(_path));
      if (_active) {
        setState(() {
          _copy = Map<String, dynamic>.from(
            r['data'] is Map ? r['data'] as Map : r,
          );
          _unavailable = false;
        });
      }
    } catch (_) {
      if (_active) {
        setState(() {
          _copy = null;
          _unavailable = true;
        });
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    final confirmed = await confirmWellnessAction(
      context,
      title: 'Stop sharing this copy?',
      message:
          'Your provider will no longer be able to open this copy in Cozy. This cannot erase anything they already read or saved outside Cozy.',
      action: 'Stop sharing',
    );
    if (!confirmed || !mounted || !_active) return;
    setState(() => _busy = true);
    try {
      await _api.delete(_path);
      if (_active) {
        setState(() {
          _copy = null;
          _unavailable = true;
        });
      }
    } catch (_) {
      if (mounted && _active) {
        await showWellnessDialog<void>(
          context: context,
          builder: (c) => WellnessSheet(
            title: 'Could not stop sharing',
            children: [
              const Text(
                'Check your connection and try again. Access has not been confirmed as withdrawn.',
              ),
            ],
          ),
        );
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WellnessSheet(
    title: _unavailable ? 'Shared copy unavailable' : 'Shared written copy',
    busy: _busy,
    children: [
      if (_busy) const LinearProgressIndicator(),
      if (_copy != null) ...[
        Text(((_copy!['entry'] as Map)['title'] ?? '').toString()),
        SelectableText((_copy!['entry'] as Map)['body'].toString()),
        const Text('Later edits to your journal are private.'),
      ],
      if (_unavailable)
        const Text(
          'The copy may have been withdrawn, removed, or sharing access changed. You may also be offline.',
        ),
      WellnessAction(label: 'Refresh copy', onPressed: _busy ? null : _load),
      WellnessAction(
        label: 'Stop sharing this copy',
        onPressed: _busy ? null : _withdraw,
      ),
    ],
  );
}
