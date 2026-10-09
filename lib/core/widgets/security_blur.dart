import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/screen_capture_service.dart';

/// Registers sensitive content; the root overlay also covers dialogs/sheets.
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

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ScreenCaptureService.instance;
    WidgetsBinding.instance.addObserver(this);
    _service.acquire();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _service.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SecurityCaptureOverlay(service: _service, child: widget.child);
}

class SecurityCaptureOverlay extends StatelessWidget {
  const SecurityCaptureOverlay({super.key, required this.child, this.service});
  final Widget child;
  final ScreenCaptureService? service;

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
}
