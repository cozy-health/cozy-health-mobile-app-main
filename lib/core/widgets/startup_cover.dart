import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/cozy_colors.dart';
import '../utils/motion.dart';
import 'app_button.dart';
import 'startup_motion.dart';

/// Keeps the destination mounted while its first usable frame is prepared.
class StartupCover extends StatefulWidget {
  const StartupCover({super.key, required this.child, this.motionBuilder});
  final Widget child;

  /// Supplies a controllable clip in tests; production uses the bundled video.
  final Widget Function(VoidCallback onComplete)? motionBuilder;

  static void ready(BuildContext context) =>
      context.findAncestorStateOfType<_StartupCoverState>()?._ready();

  static void retryWith(BuildContext context, VoidCallback retry) {
    context.findAncestorStateOfType<_StartupCoverState>()?._retry = retry;
  }

  @override
  State<StartupCover> createState() => _StartupCoverState();
}

class _StartupCoverState extends State<StartupCover>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _exit;
  Timer? _minimum, _timeout;
  bool _revealed = false, _scheduled = false, _failed = false;
  bool _minimumElapsed = false, _motionComplete = false;
  VoidCallback? _retry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _exit = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _exit.duration = context.cozyColors.wellness.launchExit;
    _minimum ??= Timer(context.cozyColors.wellness.launchMinimum, () {
      _minimumElapsed = true;
      if (_scheduled) _finish();
    });
    _armTimeout();
    if (_scheduled && shouldReduceMotion(context)) _finish();
  }

  void _armTimeout() {
    _timeout ??= Timer(context.cozyColors.wellness.launchTimeout, () {
      if (mounted && !_revealed && !_exit.isAnimating) {
        setState(() => _failed = true);
      }
    });
  }

  void _ready() {
    if (_revealed || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldReduceMotion(context) || _minimumElapsed) {
        _finish();
      }
    });
  }

  Future<void> _finish() async {
    if (!mounted || _revealed) return;
    if ((!_minimumElapsed || !_motionComplete) &&
        !shouldReduceMotion(context)) {
      return;
    }
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.hidden) {
      return;
    }
    _minimum?.cancel();
    _timeout?.cancel();
    if (!shouldReduceMotion(context)) await _exit.forward();
    if (mounted) setState(() => _revealed = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _exit.stop();
    } else if (state == AppLifecycleState.resumed && _scheduled) {
      _finish();
    }
  }

  void _motionFinished() {
    _motionComplete = true;
    if (_scheduled) unawaited(_finish());
  }

  void _tryAgain() {
    setState(() {
      _failed = false;
      _scheduled = false;
      _motionComplete = true;
    });
    _timeout?.cancel();
    _timeout = null;
    _retry?.call();
    _armTimeout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _minimum?.cancel();
    _timeout?.cancel();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: !_revealed,
          child: IgnorePointer(ignoring: !_revealed, child: widget.child),
        ),
        if (!_revealed)
          FadeTransition(
            key: const ValueKey('startup-cover-exit'),
            opacity: Tween<double>(
              begin: 1,
              end: 0,
            ).animate(CurvedAnimation(parent: _exit, curve: w.exitCurve)),
            child: ColoredBox(
              key: const ValueKey('startup-cover'),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: !_failed && !shouldReduceMotion(context)
                  ? (widget.motionBuilder?.call(_motionFinished) ??
                        StartupMotion(onComplete: _motionFinished))
                  : SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(w.section),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ScaleTransition(
                                key: const ValueKey('startup-icon-scale'),
                                scale:
                                    Tween<double>(
                                      begin: 1,
                                      end: w.launchEndScale,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _exit,
                                        curve: w.exitCurve,
                                      ),
                                    ),
                                child: const StartupIcon(),
                              ),
                              if (_failed) ...[
                                SizedBox(height: w.section),
                                const Text(
                                  'Your space is taking longer to open. Please try again.',
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: w.gap),
                                AppButton(
                                  text: 'Try again',
                                  onPressed: _tryAgain,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }
}

/// The shared icon used during local startup preparation.
class StartupIcon extends StatelessWidget {
  const StartupIcon({super.key});
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/icon/app_icon.png',
    width: context.cozyColors.wellness.launchIcon,
    height: context.cozyColors.wellness.launchIcon,
    semanticLabel: 'Cozy Health',
  );
}

/// Signals a non-Home destination after its guarded content has been built.
class StartupDestination extends StatelessWidget {
  const StartupDestination({
    super.key,
    required this.child,
    required this.ready,
  });
  final Widget child;
  final bool ready;
  @override
  Widget build(BuildContext context) {
    if (ready) StartupCover.ready(context);
    return child;
  }
}
