import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/next_of_kin_contact.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/app_surface.dart';
import '../../data/next_of_kin_repository.dart';
import '../../services/crisis_launcher.dart';

class NextOfKinPanel extends StatefulWidget {
  const NextOfKinPanel({
    super.key,
    this.repository,
    this.launcher = const CrisisLauncher(),
  });
  final NextOfKinRepository? repository;
  final CrisisLauncher launcher;

  @override
  State<NextOfKinPanel> createState() => _NextOfKinPanelState();
}

class _NextOfKinPanelState extends State<NextOfKinPanel> {
  static const helpMessage =
      'I need support right now. Please call me or check on me as soon as you can.';
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relationship = TextEditingController();
  final _message = TextEditingController(text: helpMessage);
  late final _repository = widget.repository ?? NextOfKinRepository();
  late final _scope = LocalDbService().boxName(
    LocalDbService.userSettingsBoxName,
  );
  NextOfKinContact? _contact;
  bool _loading = true, _editing = false, _review = false, _busy = false;
  String? _error;
  bool? _failedSms;
  bool _loadFailed = false;
  bool get _active =>
      mounted &&
      _scope == LocalDbService().boxName(LocalDbService.userSettingsBoxName);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    bool loaded = false;
    try {
      final contact = await _repository.load();
      if (!mounted || !_active) return;
      setState(() {
        _contact = contact;
        _loading = false;
        _loadFailed = false;
      });
      loaded = true;
      await _repository.refresh();
      final refreshed = await _repository.load();
      if (_active && !_editing && !_review && !_busy) {
        setState(() => _contact = refreshed);
      }
    } catch (_) {
      if (_active) {
        setState(() {
          _loading = false;
          _loadFailed = !loaded;
        });
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _relationship, _message]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _edit() {
    _name.text = _contact?.name ?? '';
    _phone.text = _contact?.phone ?? '';
    _relationship.text = _contact?.relationship ?? '';
    setState(() {
      _editing = true;
      _error = null;
      _failedSms = null;
    });
  }

  Future<void> _save() async {
    if (_busy || !_active || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final contact = NextOfKinContact(
      name: _name.text.trim(),
      phone: NextOfKinContact.normalizePhone(_phone.text),
      relationship: _relationship.text.trim(),
    );
    try {
      await _repository.save(contact);
      if (_active) {
        setState(() {
          _contact = contact;
          _editing = false;
          _message.text = helpMessage;
        });
      }
    } catch (_) {
      if (_active) {
        setState(
          () => _error = 'Could not save your contact. Please try again.',
        );
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Text('${_contact!.name}\n${_contact!.phone}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _remove() async {
    if (_busy || !_active) return;
    setState(() => _busy = true);
    try {
      if (!await _confirm('Remove next of kin?', 'Remove') || !_active) return;
      await _repository.save(null);
      if (_active) {
        setState(() {
          _contact = null;
          _editing = false;
          _error = null;
          _failedSms = null;
          _message.text = helpMessage;
        });
      }
    } catch (_) {
      if (_active) {
        setState(
          () => _error = 'Could not remove your contact. Please try again.',
        );
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _launch(bool sms) async {
    if (_busy || !_active || _contact == null) return;
    if (sms && _message.text.trim().isEmpty) {
      setState(() => _error = 'Enter a message before opening Messages.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _failedSms = null;
    });
    try {
      if (!sms &&
          (!await _confirm('Call your next of kin?', 'Call') || !_active)) {
        return;
      }
      final result = sms
          ? await widget.launcher.sendSms(
              _contact!.phone,
              body: _message.text.trim(),
            )
          : await widget.launcher.callPhone(_contact!.phone);
      if (!mounted || !_active) return;
      setState(() {
        if (result != LaunchResult.success) {
          _failedSms = sms;
          _error = sms
              ? 'Could not open Messages. Your message is still here. Retry or copy the details below.'
              : 'Could not open your phone app. Retry or copy the number below.';
        }
      });
      if (result == LaunchResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sms
                  ? 'Messages opened. Press Send there to send your request. Delivery cannot be confirmed here.'
                  : 'Phone app opened. Complete the call there.',
            ),
          ),
        );
      }
    } catch (_) {
      if (_active) {
        setState(() {
          _failedSms = sms;
          _error = 'Could not open the app. Retry or copy the details below.';
        });
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = _contact;
    return Scaffold(
      appBar: AppBar(title: const Text('Next of kin')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadFailed
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load your next of kin. Your saved data has not been changed.',
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry loading'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Reach someone you trust'),
                    const SizedBox(height: 12),
                    const Text(
                      'This feature contacts your next of kin. It does not dispatch emergency assistance.',
                    ),
                    const SizedBox(height: 24),
                    if (_editing || contact == null) ...[
                      Text(
                        contact == null
                            ? 'Add your next of kin'
                            : 'Edit next of kin',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _form,
                        onChanged: () => _editing = true,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Name',
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Enter their name'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _relationship,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Relationship (optional)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'International phone number',
                                helperText: 'Include + and the country code',
                                helperMaxLines: 2,
                              ),
                              validator: (value) =>
                                  NextOfKinContact.validPhone(value ?? '')
                                  ? null
                                  : 'Enter a number with + and its country code',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Text(_busy ? 'Saving…' : 'Save next of kin'),
                      ),
                      if (contact != null)
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() => _editing = false),
                          child: const Text('Cancel'),
                        ),
                    ] else ...[
                      Material(
                        shape: AppSurface.shape(
                          context,
                          BorderRadius.circular(16),
                        ),
                        color: Theme.of(context).colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (contact.relationship.isNotEmpty)
                                Text(contact.relationship),
                              SelectableText(contact.phone),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_review) ...[
                        const Text('Review your help request'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _message,
                          maxLines: null,
                          minLines: 3,
                          maxLength: 1000,
                          decoration: const InputDecoration(
                            labelText: 'Message',
                          ),
                        ),
                        const Text(
                          'This opens your messaging app. You must press Send there. Cozy Health cannot confirm sending or delivery.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _busy ? null : () => _launch(true),
                          child: const Text('Open Messages'),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _review = false;
                                  _error = null;
                                  _failedSms = null;
                                }),
                          child: const Text('Cancel'),
                        ),
                      ] else ...[
                        FilledButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                  _review = true;
                                  _error = null;
                                  _failedSms = null;
                                }),
                          child: const Text('Prepare help message'),
                        ),
                        OutlinedButton(
                          onPressed: _busy ? null : () => _launch(false),
                          child: const Text('Call next of kin'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _edit,
                          child: const Text('Edit next of kin'),
                        ),
                        TextButton(
                          onPressed: _busy ? null : _remove,
                          child: const Text('Remove next of kin'),
                        ),
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(liveRegion: true, child: Text(_error!)),
                      if (_failedSms != null) ...[
                        OutlinedButton(
                          onPressed: _busy ? null : () => _launch(_failedSms!),
                          child: const Text('Try again'),
                        ),
                        TextButton(
                          onPressed: () => Clipboard.setData(
                            ClipboardData(text: contact!.phone),
                          ),
                          child: const Text('Copy number'),
                        ),
                        if (_failedSms == true)
                          TextButton(
                            onPressed: () => Clipboard.setData(
                              ClipboardData(text: _message.text),
                            ),
                            child: const Text('Copy message'),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
