import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// A local, silent, one-shot clip. Failure never blocks session preparation.
class StartupMotion extends StatefulWidget {
  const StartupMotion({super.key, required this.onComplete});
  final VoidCallback onComplete;
  static const asset = 'assets/motion/cozy_splash_v2.mp4';
  static const poster = 'assets/motion/cozy_splash_v2_poster.png';
  static const background = Color(0xFFFAF9F5);

  @override
  State<StartupMotion> createState() => _StartupMotionState();
}

class _StartupMotionState extends State<StartupMotion>
    with WidgetsBindingObserver {
  VideoPlayerController? _player;
  Timer? _deadline;
  bool _complete = false, _initialized = false, _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _deadline = Timer(const Duration(seconds: 3), _finish);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      if (!kIsWeb &&
          defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.macOS) {
        _finish();
        return;
      }
      final player = VideoPlayerController.asset(
        StartupMotion.asset,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );
      _player = player;
      player.addListener(_changed);
      await player.initialize();
      if (!mounted || _complete) return;
      await player.setVolume(0);
      await player.setLooping(false);
      if (!mounted || _complete) return;
      setState(() => _initialized = true);
      if (_foreground) await player.play();
    } catch (_) {
      _finish();
    }
  }

  void _changed() {
    final value = _player?.value;
    if (value == null) return;
    if (value.hasError || value.isCompleted) _finish();
  }

  void _finish() {
    if (!mounted || _complete) return;
    _complete = true;
    _deadline?.cancel();
    final player = _player;
    if (player != null) unawaited(player.pause().catchError((Object _) {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onComplete();
    });
    // Completion may arrive between frames while the local destination waits.
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    final player = _player;
    if (player == null || !_initialized || _complete) return;
    if (_foreground) {
      unawaited(player.play().catchError((Object _) => _finish()));
    } else {
      unawaited(player.pause().catchError((Object _) => _finish()));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _deadline?.cancel();
    final player = _player;
    if (player != null) {
      player.removeListener(_changed);
      unawaited(player.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ColoredBox(
      color: StartupMotion.background,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: _initialized && !_complete && _player != null
              ? VideoPlayer(_player!)
              : Image.asset(StartupMotion.poster, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}
