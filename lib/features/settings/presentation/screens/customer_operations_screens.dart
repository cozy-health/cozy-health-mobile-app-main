import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/security_blur.dart';
import '../../data/customer_operations.dart';

class _Action extends StatelessWidget {
  const _Action(this.label, this.onPressed, {super.key});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final tokens = context.cozyColors.wellness;
    return AppPressable(
      label: label,
      onPressed: onPressed,
      child: Container(
        constraints: BoxConstraints(minHeight: tokens.touch),
        padding: EdgeInsets.all(tokens.small),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onPressed == null
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class SupportInboxScreen extends StatefulWidget {
  const SupportInboxScreen({super.key, this.repository});
  final CustomerOperations? repository;
  @override
  State<SupportInboxScreen> createState() => _SupportInboxScreenState();
}

class _SupportInboxScreenState extends State<SupportInboxScreen> {
  late final _repository = widget.repository ?? CustomerOperations();
  OperationsPage<SupportCase>? _items;
  int _page = 1, _load = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final load = ++_load;
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final value = await _repository.support(_page);
      if (mounted && _repository.current && load == _load) {
        setState(() => _items = value);
      }
    } catch (_) {
      if (mounted && load == _load) {
        setState(
          () => _error = 'Could not load your conversations. Please retry.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => SecurityBlur(
    child: Scaffold(
      appBar: AppBar(title: const Text('My support conversations')),
      body: ListView(
        padding: EdgeInsets.all(context.cozyColors.wellness.page),
        children: [
          const Text(
            'Support is not an emergency service. For urgent help, use emergency resources.',
          ),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
          _Action('Refresh conversations', _refresh),
          if (_items == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_items?.items.isEmpty == true)
            const Text(
              'No conversations yet. Send a problem report from Help & Support.',
            ),
          for (final item in _items?.items ?? <SupportCase>[])
            _Action(
              '${item.subject} · ${item.status}',
              () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SupportConversationScreen(
                      id: item.id,
                      repository: _repository,
                    ),
                  ),
                );
                if (mounted && _repository.current) _refresh();
              },
              key: ValueKey('support-case-${item.id}'),
            ),
          Row(
            children: [
              Expanded(
                child: _Action(
                  'Previous page',
                  _items != null && _page > 1
                      ? () {
                          _page--;
                          _refresh();
                        }
                      : null,
                ),
              ),
              Expanded(
                child: _Action(
                  'Next page',
                  _items != null && _page < (_items?.lastPage ?? 1)
                      ? () {
                          _page++;
                          _refresh();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class SupportConversationScreen extends StatefulWidget {
  const SupportConversationScreen({
    super.key,
    required this.id,
    this.repository,
  });
  final int id;
  final CustomerOperations? repository;
  @override
  State<SupportConversationScreen> createState() =>
      _SupportConversationScreenState();
}

class _SupportConversationScreenState extends State<SupportConversationScreen> {
  late final _repository = widget.repository ?? CustomerOperations();
  final _body = TextEditingController();
  SupportCase? _thread;
  String? _error, _notice, _sentBody;
  String _requestId = const Uuid().v4();
  bool _busy = false;
  int _load = 0;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final load = ++_load;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final value = await _repository.conversation(widget.id);
      if (mounted && _repository.current && load == _load) {
        setState(() => _thread = value);
      }
    } catch (_) {
      if (mounted && load == _load) {
        setState(
          () => _error =
              'Could not refresh. Your draft is still here; please retry.',
        );
      }
    } finally {
      if (mounted && load == _load) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final thread = _thread, body = _body.text.trim();
    if (_busy || thread == null || body.isEmpty) return;
    if (_sentBody != body) {
      _requestId = const Uuid().v4();
      _sentBody = body;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final value = await _repository.reply(
        widget.id,
        thread.version,
        body,
        _requestId,
      );
      if (!mounted || !_repository.current) return;
      _body.clear();
      _sentBody = null;
      setState(() {
        _thread = value;
        _notice = 'Reply saved. Support will see it in this conversation.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not confirm your reply. Your draft is still here. Refresh the conversation before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SecurityBlur(
    child: Scaffold(
      appBar: AppBar(title: const Text('Support conversation')),
      body: ListView(
        padding: EdgeInsets.all(context.cozyColors.wellness.page),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _Action('Refresh conversation', _busy ? null : _refresh),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
          if (_notice != null)
            Semantics(liveRegion: true, child: Text(_notice!)),
          if (_thread case final thread?) ...[
            Text(thread.subject, style: Theme.of(context).textTheme.titleLarge),
            Text('Status: ${thread.status}'),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.cozyColors.wellness.gap,
              ),
              child: Text('You: ${thread.message}'),
            ),
            for (final reply in thread.messages)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: context.cozyColors.wellness.small,
                ),
                child: Text(
                  '${reply.author == 'customer' ? 'You' : 'Support'}: ${reply.body}',
                ),
              ),
            TextField(
              key: const ValueKey('support-reply'),
              controller: _body,
              enabled: !_busy,
              maxLength: 10000,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Your reply'),
              onChanged: (_) => setState(() {}),
            ),
            _Action(
              'Send reply',
              _busy || _body.text.trim().isEmpty ? null : _send,
              key: const ValueKey('support-send'),
            ),
          ],
        ],
      ),
    ),
  );
}

class PrivacyRequestsScreen extends StatefulWidget {
  const PrivacyRequestsScreen({super.key, this.repository});
  final CustomerOperations? repository;
  @override
  State<PrivacyRequestsScreen> createState() => _PrivacyRequestsScreenState();
}

class _PrivacyRequestsScreenState extends State<PrivacyRequestsScreen> {
  late final _repository = widget.repository ?? CustomerOperations();
  final _password = TextEditingController(), _value = TextEditingController();
  String _kind = 'export', _field = 'name', _requestId = const Uuid().v4();
  String? _error, _notice, _payloadKey;
  bool _confirmed = false, _busy = false;
  int _page = 1;
  OperationsPage<CustomerPrivacyRequest>? _items;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _password.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final value = await _repository.privacy(_page);
      if (mounted && _repository.current) setState(() => _items = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not load your privacy requests. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy ||
        !_confirmed ||
        _password.text.isEmpty ||
        (_kind == 'correction' && _value.text.trim().isEmpty)) {
      return;
    }
    final key = '$_kind:$_field:${_value.text.trim()}';
    if (_payloadKey != key) {
      _requestId = const Uuid().v4();
      _payloadKey = key;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await _repository.requestPrivacy(
        kind: _kind,
        password: _password.text,
        requestId: _requestId,
        changes: _kind == 'correction' ? {_field: _value.text.trim()} : null,
      );
      if (!mounted || !_repository.current) return;
      _password.clear();
      _value.clear();
      _confirmed = false;
      _payloadKey = null;
      setState(
        () => _notice =
            'Request received for review. Your account has not been deleted or changed by submitting this request.',
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not confirm your request. Check your current password and verified email, then retry. Your entered correction is still here.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download(CustomerPrivacyRequest request) async {
    if (_busy || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await _repository.download(request.id, _password.text);
      if (!mounted || !_repository.current) return;
      _password.clear();
      final box = context.findRenderObject() as RenderBox?;
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/zip')],
          fileNameOverrides: ['cozy-account-data.zip'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
      if (mounted && _repository.current) {
        setState(
          () => _notice = result.status == ShareResultStatus.success
              ? 'Export shared.'
              : 'Export prepared. Sharing was not confirmed.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not download or share the export. Check your current password and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SecurityBlur(
    child: Scaffold(
      appBar: AppBar(title: const Text('Privacy requests')),
      body: ListView(
        padding: EdgeInsets.all(context.cozyColors.wellness.page),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          const Text(
            'Request an account-data export, a profile correction, or account deletion. These requests are reviewed. Your current password and verified email confirm your identity.',
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
          if (_notice != null)
            Semantics(liveRegion: true, child: Text(_notice!)),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Request type'),
            items: const [
              DropdownMenuItem(
                value: 'export',
                child: Text('Account-data export'),
              ),
              DropdownMenuItem(
                value: 'correction',
                child: Text('Profile correction'),
              ),
              DropdownMenuItem(
                value: 'deletion',
                child: Text('Account deletion'),
              ),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _kind = value;
                        _confirmed = false;
                      });
                    }
                  },
          ),
          if (_kind == 'correction') ...[
            DropdownButtonFormField<String>(
              initialValue: _field,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Profile field'),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(value: 'username', child: Text('Username')),
                DropdownMenuItem(value: 'bio', child: Text('Bio')),
                DropdownMenuItem(value: 'timezone', child: Text('Timezone')),
                DropdownMenuItem(
                  value: 'country_code',
                  child: Text('Country code'),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (value) {
                      if (value != null) setState(() => _field = value);
                    },
            ),
            TextField(
              controller: _value,
              enabled: !_busy,
              maxLength: 255,
              decoration: const InputDecoration(labelText: 'Correct value'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          TextField(
            key: const ValueKey('privacy-password'),
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Current password'),
            onChanged: (_) => setState(() {}),
          ),
          _Action(
            _confirmed
                ? 'Confirmed: request $_kind'
                : 'Confirm I want to request $_kind',
            _busy ? null : () => setState(() => _confirmed = !_confirmed),
            key: const ValueKey('privacy-confirm'),
          ),
          if (_kind == 'deletion')
            const Text(
              'Approval removes your account and starts private-file cleanup. This does not cancel a store subscription. Submitting the request does not immediately delete your account.',
            ),
          _Action(
            'Submit privacy request',
            !_busy &&
                    _confirmed &&
                    _password.text.isNotEmpty &&
                    (_kind != 'correction' || _value.text.trim().isNotEmpty)
                ? _submit
                : null,
            key: const ValueKey('privacy-submit'),
          ),
          const Divider(),
          Text('Your requests', style: Theme.of(context).textTheme.titleLarge),
          _Action('Refresh privacy requests', _busy ? null : _refresh),
          if (_items?.items.isEmpty == true)
            const Text('No privacy requests yet.'),
          for (final request in _items?.items ?? <CustomerPrivacyRequest>[])
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.cozyColors.wellness.small,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${request.kind} · ${request.status}'),
                  if (request.outcome != null) Text(request.outcome!),
                  if (request.kind == 'export' && request.status == 'completed')
                    _Action(
                      'Download approved export',
                      !_busy && _password.text.isNotEmpty
                          ? () => _download(request)
                          : null,
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _Action(
                  'Previous page',
                  !_busy && _page > 1
                      ? () {
                          _page--;
                          _refresh();
                        }
                      : null,
                ),
              ),
              Expanded(
                child: _Action(
                  'Next page',
                  !_busy && _items != null && _page < (_items?.lastPage ?? 1)
                      ? () {
                          _page++;
                          _refresh();
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
