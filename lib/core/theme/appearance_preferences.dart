import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Applies the app modifier without flattening Android's nonlinear scaler.
/// The normal range is 80–200%; larger device accessibility sizes remain valid.
class AppearanceTextScaler extends TextScaler {
  const AppearanceTextScaler(this.deviceScaler, this.multiplier);

  final TextScaler deviceScaler;
  final double multiplier;

  @override
  double scale(double fontSize) {
    final deviceSize = deviceScaler.scale(fontSize);
    final modifier = multiplier.isFinite ? multiplier.clamp(.8, 1.5) : 1.0;
    return (deviceSize * modifier).clamp(
      fontSize * .8,
      math.max(fontSize * 2, deviceSize),
    );
  }

  @override
  double get textScaleFactor => scale(1);

  @override
  bool operator ==(Object other) =>
      other is AppearanceTextScaler &&
      other.deviceScaler == deviceScaler &&
      other.multiplier == multiplier;

  @override
  int get hashCode => Object.hash(deviceScaler, multiplier);
}

MediaQueryData appearanceMediaQuery(
  MediaQueryData device, {
  double textMultiplier = 1,
  bool highContrast = false,
  bool reduceMotion = false,
}) {
  final reduce =
      reduceMotion || device.disableAnimations || device.accessibleNavigation;
  return device.copyWith(
    textScaler: AppearanceTextScaler(device.textScaler, textMultiplier),
    highContrast: device.highContrast || highContrast,
    boldText: device.boldText || highContrast,
    disableAnimations: reduce,
    accessibleNavigation: device.accessibleNavigation || reduce,
  );
}

/// Captured dialog/sheet themes retain a dependency on the live app theme.
/// This sits below MaterialApp's Theme, so its captured wrapper takes precedence.
class LiveAppearanceTheme extends InheritedTheme {
  const LiveAppearanceTheme({
    super.key,
    required this.theme,
    required super.child,
  });

  final ThemeData theme;

  @override
  bool updateShouldNotify(LiveAppearanceTheme oldWidget) =>
      theme != oldWidget.theme;

  @override
  Widget wrap(BuildContext context, Widget child) => Builder(
    builder: (context) {
      final live = context
          .dependOnInheritedWidgetOfExactType<LiveAppearanceTheme>();
      return Theme(data: live?.theme ?? theme, child: child);
    },
  );
}
