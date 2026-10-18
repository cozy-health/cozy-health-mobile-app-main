import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../data/demo_mode.dart';
import '../routing/app_router.dart';
import '../services/affirmation_controller.dart';
import '../repositories/affirmation_repository.dart';

class AffirmationPanel extends StatefulWidget {
  const AffirmationPanel({super.key, this.controller, this.compact = false});
  final AffirmationController? controller;
  final bool compact;
  @override
  State<AffirmationPanel> createState() => _AffirmationPanelState();
}

class _AffirmationPanelState extends State<AffirmationPanel>
    with WidgetsBindingObserver {
  late final _controller = widget.controller ?? AffirmationController.instance;
  late final bool _live =
      !DemoMode.instance.enabled || widget.controller != null;
  bool _attached = false;
  bool _reading = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _readIfVisible();
  }

  void _readIfVisible() {
    if (_live &&
        _attached &&
        !_reading &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
        !widget.compact &&
        _controller.state.assignment != null &&
        _controller.state.status == AffirmationStatus.ready) {
      _reading = true;
      unawaited(
        AffirmationRepository()
            .markRead()
            .catchError((Object _) {})
            .whenComplete(() => _reading = false),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = _live && TickerMode.valuesOf(context).enabled;
    if (active && !_attached) {
      _attached = true;
      _controller.addListener(_changed);
      _controller.attach();
      _readIfVisible();
    } else if (!active && _attached) {
      _attached = false;
      _controller.removeListener(_changed);
      _controller.detach();
    }
  }

  void _changed() {
    _readIfVisible();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_attached) {
      _controller.removeListener(_changed);
      _controller.detach();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _live ? _controller.state : const AffirmationState();
    final label = _live ? _controller.label : 'General encouragement';
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
          textAlign: widget.compact ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          state.text,
          key: const Key('affirmation-body'),
          textAlign: widget.compact ? TextAlign.start : TextAlign.center,
          style: widget.compact
              ? Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
              : Theme.of(context).textTheme.headlineSmall,
        ),
        if (state.status == AffirmationStatus.loading) ...[
          const SizedBox(height: 8),
          const Text('Refreshing affirmation…'),
        ],
        if (state.canRetry) ...[
          const SizedBox(height: 8),
          Text(
            state.status == AffirmationStatus.empty
                ? 'No assigned affirmations are available right now.'
                : 'Could not refresh your affirmation.',
          ),
          TextButton(
            onPressed: () => _controller.refresh(force: true),
            child: const Text('Retry affirmation'),
          ),
        ],
        if (widget.compact)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Read affirmation',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
          ),
      ],
    );
    if (!widget.compact) return content;
    return Semantics(
      button: true,
      label: 'Open daily affirmation',
      child: InkWell(
        key: const Key('home-affirmation-card'),
        onTap: () => context.push(AppRouter.dailyAffirmation),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: content,
        ),
      ),
    );
  }
}
