import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class CozyColors extends ThemeExtension<CozyColors> {
  const CozyColors({
    required this.crisis,
    required this.calendarBg,
    required this.journalingBg,
    required this.quizBg,
    required this.triggerLow,
    required this.triggerMed,
    required this.triggerHigh,
  });
  final Color crisis,
      calendarBg,
      journalingBg,
      quizBg,
      triggerLow,
      triggerMed,
      triggerHigh;

  static const light = CozyColors(
    crisis: AppColors.crisisPrimary,
    calendarBg: AppColors.accentPeach,
    journalingBg: AppColors.accentSage,
    quizBg: AppColors.accentSky,
    triggerLow: AppColors.success,
    triggerMed: AppColors.warmOrange,
    triggerHigh: AppColors.danger,
  );
  static const dark = CozyColors(
    crisis: Color(0xFFFF8A6A),
    calendarBg: AppColors.accentPeachDark,
    journalingBg: AppColors.accentSageDark,
    quizBg: AppColors.accentSkyDark,
    triggerLow: Color(0xFF69D68C),
    triggerMed: Color(0xFFFFAB70),
    triggerHigh: Color(0xFFFF8585),
  );

  @override
  CozyColors copyWith({
    Color? crisis,
    Color? calendarBg,
    Color? journalingBg,
    Color? quizBg,
    Color? triggerLow,
    Color? triggerMed,
    Color? triggerHigh,
  }) => CozyColors(
    crisis: crisis ?? this.crisis,
    calendarBg: calendarBg ?? this.calendarBg,
    journalingBg: journalingBg ?? this.journalingBg,
    quizBg: quizBg ?? this.quizBg,
    triggerLow: triggerLow ?? this.triggerLow,
    triggerMed: triggerMed ?? this.triggerMed,
    triggerHigh: triggerHigh ?? this.triggerHigh,
  );

  @override
  CozyColors lerp(covariant CozyColors? other, double t) => other == null
      ? this
      : CozyColors(
          crisis: Color.lerp(crisis, other.crisis, t)!,
          calendarBg: Color.lerp(calendarBg, other.calendarBg, t)!,
          journalingBg: Color.lerp(journalingBg, other.journalingBg, t)!,
          quizBg: Color.lerp(quizBg, other.quizBg, t)!,
          triggerLow: Color.lerp(triggerLow, other.triggerLow, t)!,
          triggerMed: Color.lerp(triggerMed, other.triggerMed, t)!,
          triggerHigh: Color.lerp(triggerHigh, other.triggerHigh, t)!,
        );
}

extension CozyColorContext on BuildContext {
  CozyColors get cozyColors =>
      Theme.of(this).extension<CozyColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? CozyColors.dark
          : CozyColors.light);
}
