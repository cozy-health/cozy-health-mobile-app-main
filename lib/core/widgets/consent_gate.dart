import 'package:flutter/material.dart';
import '../routing/app_router.dart';
import '../services/consent_service.dart';
import '../storage/token_storage.dart';

class ConsentGate extends StatefulWidget {
  const ConsentGate({
    super.key,
    required this.child,
    this.service,
    this.observeRoutes = true,
  });
  final Widget child;
  final ConsentService? service;
  final bool observeRoutes;
  @override
  State<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<ConsentGate> with WidgetsBindingObserver {
  late final ConsentService _service;
  ConsentState? _state;
  String? _session;
  bool _loading = false, _busy = false;
  String? _error;
  final Set<String> _dismissed = {};
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ConsentService();
    WidgetsBinding.instance.addObserver(this);
    if (widget.observeRoutes) {
      AppRouter.router.routeInformationProvider.addListener(_routeChanged);
    }
    _refresh();
  }

  Future<void> _routeChanged() async {
    final token = await TokenStorage().getToken();
    if (token == null && mounted) {
      setState(() {
        _state = null;
        _session = null;
        _dismissed.clear();
      });
    }
    if (token != null && token != _session) await _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final result = await _service.load();
      final token = await TokenStorage().getToken();
      if (mounted) {
        setState(() {
          _state = result;
          _session = token;
        });
      }
    } catch (_) {
      // Draft rollout must not lock out users on connectivity failures.
    } finally {
      _loading = false;
    }
  }

  Future<void> _review(ConsentDocument doc) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(doc.title),
        content: SingleChildScrollView(
          child: Text(
            doc.reviewable
                ? doc.content!
                : 'This document is still a draft. We will notify you when the approved text is published.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (doc.reviewable)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _accept(doc);
              },
              child: const Text('Accept'),
            ),
        ],
      ),
    );
  }

  Future<void> _accept(ConsentDocument doc) async {
    if (_busy || _state == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.accept(_state!, doc);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save your choice. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.observeRoutes) {
      AppRouter.router.routeInformationProvider.removeListener(_routeChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _state?.pending ?? [];
    final required = pending.where((doc) => _state!.blocking(doc)).toList();
    if (required.isNotEmpty) {
      final doc = required.first;
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  doc.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Expanded(
                  child: SingleChildScrollView(child: Text(doc.content!)),
                ),
                if (_error != null) Text(_error!),
                FilledButton(
                  onPressed: _busy ? null : () => _accept(doc),
                  child: Text(_busy ? 'Saving…' : 'Accept'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final notices = pending
        .where((doc) => !_dismissed.contains('${doc.type}:${doc.version}'))
        .toList();
    if (notices.isEmpty) return widget.child;
    final doc = notices.first;
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: MaterialBanner(
            content: Text("We've updated our ${doc.title}. Tap to review."),
            actions: [
              TextButton(
                onPressed: () => _review(doc),
                child: const Text('Review'),
              ),
              TextButton(
                onPressed: () => setState(
                  () => _dismissed.add('${doc.type}:${doc.version}'),
                ),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
