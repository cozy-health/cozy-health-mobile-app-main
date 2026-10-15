import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

extension CommunityTheme on BuildContext {
  bool get communityIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get communityBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get communitySurface => Theme.of(this).colorScheme.surface;

  Color get communitySurfaceElevated =>
      Theme.of(this).colorScheme.surfaceContainerHigh;

  Color get communityText => Theme.of(this).colorScheme.onSurface;

  Color get communityMuted => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get communitySubtle => Theme.of(this).colorScheme.onSurfaceVariant;

  Color get communityBorder => Theme.of(this).colorScheme.outline;

  Color get communityStrongBorder => Theme.of(this).colorScheme.outline;

  TextStyle get communityHeading1 =>
      AppTextStyles.heading1.copyWith(color: communityText);

  TextStyle get communityHeading2 =>
      AppTextStyles.heading2.copyWith(color: communityText);

  TextStyle get communityHeading3 =>
      AppTextStyles.heading3.copyWith(color: communityText);

  TextStyle get communityBody1 =>
      AppTextStyles.body1.copyWith(color: communityText);

  TextStyle get communityBody2 =>
      AppTextStyles.body2.copyWith(color: communityMuted);
}
