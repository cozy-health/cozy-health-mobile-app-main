import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform-appropriate subtle haptics for native tactile feedback.
class AppHaptics {
  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static void selection() {
    if (_supported) HapticFeedback.selectionClick();
  }

  static void light() {
    if (_supported) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_supported) HapticFeedback.mediumImpact();
  }
}
