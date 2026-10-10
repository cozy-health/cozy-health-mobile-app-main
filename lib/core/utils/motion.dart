import 'package:flutter/material.dart';

/// Root MediaQuery combines the saved app preference with device preferences.
bool shouldReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);

Duration motionDuration(BuildContext context, Duration duration) =>
    shouldReduceMotion(context) ? Duration.zero : duration;

class NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoMotionPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

ThemeData motionTheme(ThemeData theme, bool reduceMotion) => reduceMotion
    ? theme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoMotionPageTransitionsBuilder(),
            TargetPlatform.iOS: NoMotionPageTransitionsBuilder(),
            TargetPlatform.macOS: NoMotionPageTransitionsBuilder(),
            TargetPlatform.windows: NoMotionPageTransitionsBuilder(),
            TargetPlatform.linux: NoMotionPageTransitionsBuilder(),
            TargetPlatform.fuchsia: NoMotionPageTransitionsBuilder(),
          },
        ),
      )
    : theme;
