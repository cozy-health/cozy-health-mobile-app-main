import 'dart:async';
import 'package:flutter/material.dart';
import '../routing/app_router.dart';
import '../services/legal_documents.dart';
import '../services/consent_service.dart';
import '../services/consent_refresh_signal.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_service.dart';

class ConsentGate extends StatefulWidget {
  const ConsentGate({
    super.key,
    required this.child,
    this.service,
    this.observeRoutes = true,
    this.forceBlocking = false,
  });
  final Widget child;
  final ConsentService? service;
  final bool observeRoutes;
  final bool forceBlocking;
  @override
  State<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<ConsentGate> with WidgetsBindingObserver {
  late final ConsentService _service;
  ConsentState? _state;
  String? _session;
  bool _loading = false, _busy = false;
  bool _verified = false;
  int _request = 0;
  StreamSubscription<void>? _clearing, _sessions;
  String? _loadError;
  String? _error;
  final Set<String> _dismissed = {};
  final Set<String> _healthChoices = {};
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ConsentService();
    consentRefreshSignal.addListener(_consentRequired);
    _clearing = TokenStorage.sessionClearing.listen((_) => _invalidate());
    _sessions = TokenStorage.sessionChanges.listen((_) {
      _invalidate();
      _refresh();
    });
    WidgetsBinding.instance.addObserver(this);
    if (widget.observeRoutes) {
      AppRouter.router.routeInformationProvider.addListener(_routeChanged);
    }
    _refresh();
  }

  Future<void> _routeChanged() async {
    if (mounted) {
      setState(() {}); // Rebuild to expose crisis routes immediately.
    }
    final token = await TokenStorage().getToken();
    if (token != _session && mounted) {
      setState(() {
        _state = null;
        _healthChoices.clear();
        _dismissed.clear();
      });
    }
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
    final request = ++_request;
    final generation = TokenStorage.generation;
    setState(() {
      _loading = true;
      _verified = false;
      _loadError = null;
    });
    try {
      final result = await _service.load();
      final token = await TokenStorage().getToken();
      if (mounted &&
          request == _request &&
          generation == TokenStorage.generation) {
        setState(() {
          _state = result;
          _session = token;
          _verified = true;
        });
      }
    } catch (_) {
      if (mounted &&
          request == _request &&
          generation == TokenStorage.generation) {
        setState(() {
          _state = null;
          _loadError =
              'Could not check your consent. Check your connection and retry.';
        });
      }
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _invalidate() {
    if (!mounted) return;
    setState(() {
      _request++;
      _loading = false;
      _verified = false;
      _state = null;
      _session = null;
      _busy = false;
      _error = null;
      _loadError = null;
      _dismissed.clear();
      _healthChoices.clear();
    });
  }

  void _consentRequired() {
    _invalidate();
    _refresh();
  }

  Future<void> _review(ConsentDocument doc) async {
    final state = _state;
    final generation = TokenStorage.generation;
    await showDialog<void>(
      context: context,
      animationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : null,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(doc.title),
        content: SingleChildScrollView(
          child: Text(
            doc.reviewable
                ? doc.content!
                : 'This document is still a draft. We will notify you when the approved text is published.',
          ),
        ),
        actions: [
          if (doc.url != null)
            TextButton(
              onPressed: () => LegalDocuments.open(doc.url),
              child: const Text('Read online'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (doc.reviewable)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (identical(state, _state) &&
                    generation == TokenStorage.generation) {
                  _accept(doc);
                }
              },
              child: const Text('Accept'),
            ),
        ],
      ),
    );
  }

  Future<void> _accept(ConsentDocument doc) async {
    if (_busy || _state == null) return;
    final generation = TokenStorage.generation;
    final state = _state!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.accept(state, doc);
      if (mounted && generation == TokenStorage.generation) setState(() {});
    } catch (_) {
      if (mounted && generation == TokenStorage.generation) {
        setState(() => _error = 'Could not save your choice. Please retry.');
      }
    } finally {
      if (mounted && generation == TokenStorage.generation) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    consentRefreshSignal.removeListener(_consentRequired);
    _clearing?.cancel();
    _sessions?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (widget.observeRoutes) {
      AppRouter.router.routeInformationProvider.removeListener(_routeChanged);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.observeRoutes
        ? AppRouter.router.routeInformationProvider.value.uri.path
        : '';
    if ({
          AppRouter.crisisHub,
          AppRouter.crisisOverlay,
          AppRouter.crisisFollowUp,
        }.contains(path) ||
        {
          AppRouter.ageAuthorization,
          AppRouter.accountDeletion,
          AppRouter.helpSupport,
          AppRouter.reportProblem,
          AppRouter.feedback,
          AppRouter.legalHub,
          AppRouter.termsPolicies,
          AppRouter.about,
          AppRouter.emailSettings,
          AppRouter.login,
          AppRouter.welcome,
          AppRouter.createAccount,
          AppRouter.forgotPassword,
        }.contains(path) ||
        path == AppRouter.breathing ||
        path == AppRouter.grounding) {
      return widget.child;
    }
    if (!_verified) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loading) const CircularProgressIndicator(),
                  Text(_loadError ?? 'Checking your consent…'),
                  if (!_loading)
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  if (widget.observeRoutes) ...[
                    TextButton(
                      onPressed: () => AppRouter.router.go(AppRouter.crisisHub),
                      child: const Text('Get urgent support'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await AuthService().logout();
                        if (mounted) AppRouter.router.go(AppRouter.login);
                      },
                      child: const Text('Log out'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    final pending = _state?.pending ?? [];
    final required = pending
        .where(
          (doc) =>
              _state!.blocking(doc) ||
              (widget.forceBlocking && doc.required && doc.reviewable),
        )
        .toList();
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
                if (doc.url != null)
                  TextButton(
                    onPressed: () => LegalDocuments.open(doc.url),
                    child: const Text('Read online'),
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => AppRouter.router.go(AppRouter.crisisHub),
                  child: const Text('Get urgent support'),
                ),
                if (doc.type == 'health_data')
                  CheckboxListTile(
                    value: _healthChoices.contains(doc.version),
                    title: const Text(
                      'I explicitly consent to the health-data processing described above.',
                    ),
                    onChanged: _busy
                        ? null
                        : (value) => setState(() {
                            if (value == true) {
                              _healthChoices.add(doc.version);
                            } else {
                              _healthChoices.remove(doc.version);
                            }
                          }),
                  ),
                FilledButton(
                  onPressed:
                      _busy ||
                          (doc.type == 'health_data' &&
                              !_healthChoices.contains(doc.version))
                      ? null
                      : () => _accept(doc),
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
