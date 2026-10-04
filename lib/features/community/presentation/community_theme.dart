import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

extension CommunityTheme on BuildContext {
  bool get communityIsDark => Theme.of(this).brightness == Brightness.dark;

  Color get communityBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get communitySurface =>
      communityIsDark ? AppColors.surfaceDark : AppColors.surfaceLight;

  Color get communitySurfaceElevated => communityIsDark
      ? AppColors.surfaceElevatedDark
      : AppColors.surfaceElevatedLight;

  Color get communityText =>
      communityIsDark ? AppColors.textDark : AppColors.textLight;

  Color get communityMuted =>
      communityIsDark ? AppColors.textMutedDark : AppColors.textMutedLight;

  Color get communitySubtle =>
      communityIsDark ? AppColors.textSubtleDark : AppColors.textSubtleLight;

  Color get communityBorder =>
      communityIsDark ? AppColors.borderDark : AppColors.borderLight;

  Color get communityStrongBorder =>
      communityIsDark ? AppColors.borderStrongDark : AppColors.borderStrongLight;

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
