// import 'dart:ui'; // Screenshot blur disabled app-wide.
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/local_db_service.dart';
import '../storage/token_storage.dart';
import '../services/screen_capture_service.dart';

/// Screenshot protection is disabled; content remains visible during capture.
class SecurityBlur extends StatefulWidget {
  const SecurityBlur({super.key, required this.child, this.service});
  final Widget child;
  final ScreenCaptureService? service;

  @override
  State<SecurityBlur> createState() => _SecurityBlurState();
}

class _SecurityBlurState extends State<SecurityBlur>
    with WidgetsBindingObserver {
  late final ScreenCaptureService _service;
  final _owner = LocalDbService().activeUserId;
  StreamSubscription<void>? _accounts, _clearing;
  bool _ended = false;
  void _endSession() {
    if (mounted && !_ended) {
      setState(() => _ended = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ScreenCaptureService.instance;
    _accounts = LocalDbService().accountChanges.listen((_) {
      if (_owner != LocalDbService().activeUserId) {
        _endSession();
      }
    });
    _clearing = TokenStorage.sessionClearing.listen((_) => _endSession());
    WidgetsBinding.instance.addObserver(this);
    // _service.acquire(); // Screenshot protection disabled app-wide.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // if (state == AppLifecycleState.resumed) _service.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_accounts?.cancel());
    unawaited(_clearing?.cancel());
    // _service.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ended
      ? Scaffold(
          appBar: AppBar(title: const Text('Account changed')),
          body: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Reopen this page to continue with your current account.',
              ),
            ),
          ),
        )
      : SecurityCaptureOverlay(service: _service, child: widget.child);
}

class SecurityCaptureOverlay extends StatelessWidget {
  const SecurityCaptureOverlay({super.key, required this.child, this.service});
  final Widget child;
  final ScreenCaptureService? service;

  @override
  Widget build(BuildContext context) => child;

  /* Screenshot overlay disabled app-wide so users can capture any screen.
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: service ?? ScreenCaptureService.instance,
    child: child,
    builder: (context, hidden, content) {
      hidden = hidden || (service ?? ScreenCaptureService.instance).shouldHide;
      // Keep the subtree mounted so capture changes cannot discard unsaved input.
      return Stack(
        fit: StackFit.passthrough,
        children: [
          ExcludeSemantics(
            excluding: hidden,
            child: ImageFiltered(
              enabled: hidden,
              imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: content,
            ),
          ),
          if (hidden)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sensitive content is hidden during screen capture.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
      );
  */
}
