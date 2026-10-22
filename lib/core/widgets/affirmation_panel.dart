import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../data/demo_mode.dart';
import '../routing/app_router.dart';
import '../services/affirmation_controller.dart';
import '../repositories/affirmation_repository.dart';
import '../theme/cozy_colors.dart';
import 'app_pressable.dart';

class AffirmationPanel extends StatefulWidget {
  const AffirmationPanel({
    super.key,
    this.controller,
    this.compact = false,
    this.showReflection = false,
  });
  final AffirmationController? controller;
  final bool compact;
  final bool showReflection;
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
        if (!widget.compact)
          Icon(
            Icons.auto_awesome_outlined,
            size: widget.compact ? 28 : 36,
            color: Theme.of(context).colorScheme.primary,
          ),
        if (!widget.compact) const SizedBox(height: 12),
        Text(
          widget.compact ? 'A REMINDER FOR TODAY' : label,
          style: widget.compact
              ? Theme.of(context).textTheme.labelMedium
              : Theme.of(context).textTheme.labelLarge,
          textAlign: widget.compact ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          state.text,
          key: const Key('affirmation-body'),
          textAlign: widget.compact ? TextAlign.start : TextAlign.center,
          style: widget.compact
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1.4,
                )
              : Theme.of(context).textTheme.headlineSmall,
        ),
        if (widget.compact) ...[
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
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
            child: Text('Take a moment with these words  →'),
          ),
        if (widget.showReflection) ...[
          const SizedBox(height: 32),
          Text(
            'Let this meet you where you are',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(state.reflection, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 24),
          Text(
            'A small way to practise',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Take one comfortable breath. Read the affirmation slowly and choose '
            'a word that feels helpful today. Ask yourself: what is one small, '
            'kind action I can take for myself right now? It is okay if that '
            'action is simply pausing for a moment.',
            style: TextStyle(height: 1.6),
          ),
        ],
      ],
    );
    if (!widget.compact) return content;
    final t = context.cozyColors.wellness;
    return AppPressable(
      key: const Key('home-affirmation-card'),
      label: 'Open daily affirmation',
      onPressed: () => context.push(AppRouter.dailyAffirmation),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(t.gap),
        decoration: BoxDecoration(
          color: t.reminder(Theme.of(context).brightness),
          border: Border.all(
            color: MediaQuery.highContrastOf(context)
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outlineVariant,
            width: MediaQuery.highContrastOf(context) ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(t.radius),
        ),
        child: content,
      ),
    );
  }
}
