import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reference counting keeps protection active across nested sensitive routes.
class ScreenCaptureService extends ValueNotifier<bool> {
  ScreenCaptureService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('cozy_health/screen_capture'),
      super(false) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'captureChanged') {
        _captured = call.arguments == true;
        _publish();
      }
    });
  }

  static final instance = ScreenCaptureService();
  final MethodChannel _channel;
  int _users = 0;
  bool _captured = false;
  bool _ready = false;
  Future<void>? _pending;
  bool get shouldHide => _users > 0 && (!_ready || _captured);

  void acquire() {
    if (_users == 0) _ready = false;
    _users++;
    _update();
  }

  void release() {
    if (_users > 0) _users--;
    _update();
  }

  void refresh() => _update();

  void _publish() {
    // Listeners may include an ancestor currently building the sensitive route.
    scheduleMicrotask(() {
      value = shouldHide;
    });
  }

  void _update() {
    _publish();
    _pending = (_pending ?? Future<void>.value()).then((_) async {
      try {
        _captured =
            await _channel.invokeMethod<bool>('setProtected', _users > 0) ??
            false;
        _ready = true;
      } on MissingPluginException {
        // Desktop/web previews have no native capture API.
        _ready =
            kIsWeb ||
            (defaultTargetPlatform != TargetPlatform.iOS &&
                defaultTargetPlatform != TargetPlatform.android);
      } on PlatformException {
        _ready = false;
      }
      _publish();
    });
  }
}
