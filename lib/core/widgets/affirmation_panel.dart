import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/demo_mode.dart';
import '../routing/app_router.dart';
import '../services/affirmation_controller.dart';

class AffirmationPanel extends StatefulWidget {
  const AffirmationPanel({super.key, this.controller, this.compact = false});
  final AffirmationController? controller;
  final bool compact;
  @override
  State<AffirmationPanel> createState() => _AffirmationPanelState();
}

class _AffirmationPanelState extends State<AffirmationPanel> {
  late final _controller = widget.controller ?? AffirmationController.instance;
  late final bool _live =
      !DemoMode.instance.enabled || widget.controller != null;
  bool _attached = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = _live && TickerMode.valuesOf(context).enabled;
    if (active && !_attached) {
      _attached = true;
      _controller.addListener(_changed);
      _controller.attach();
    } else if (!active && _attached) {
      _attached = false;
      _controller.removeListener(_changed);
      _controller.detach();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
        child: Padding(padding: const EdgeInsets.all(4), child: content),
      ),
    );
  }
}
