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
    this.recordingCategoryFills = const [
      Color(0xFFF3F9F5),
      Color(0xFFFEF6F1),
      Color(0xFFF6F8FB),
      Color(0xFFFCF7F6),
      Color(0xFFF6E3E7),
      Color(0xFFEDF7F8),
    ],
  });
  final Color crisis,
      calendarBg,
      journalingBg,
      quizBg,
      triggerLow,
      triggerMed,
      triggerHigh;
  final List<Color> recordingCategoryFills;

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
    recordingCategoryFills: [
      Color(0xFF17251E),
      Color(0xFF2B211B),
      Color(0xFF1D2430),
      Color(0xFF292122),
      Color(0xFF302027),
      Color(0xFF19292C),
    ],
    crisis: AppColors.crisisPrimary,
    calendarBg: AppColors.accentPeachDark,
    journalingBg: AppColors.accentSageDark,
    quizBg: AppColors.accentSkyDark,
    triggerLow: AppColors.success,
    triggerMed: AppColors.warmOrange,
    triggerHigh: AppColors.danger,
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
    List<Color>? recordingCategoryFills,
  }) => CozyColors(
    crisis: crisis ?? this.crisis,
    calendarBg: calendarBg ?? this.calendarBg,
    journalingBg: journalingBg ?? this.journalingBg,
    quizBg: quizBg ?? this.quizBg,
    triggerLow: triggerLow ?? this.triggerLow,
    triggerMed: triggerMed ?? this.triggerMed,
    triggerHigh: triggerHigh ?? this.triggerHigh,
    recordingCategoryFills:
        recordingCategoryFills ?? this.recordingCategoryFills,
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
          recordingCategoryFills: [
            for (var i = 0; i < recordingCategoryFills.length; i++)
              Color.lerp(
                recordingCategoryFills[i],
                other.recordingCategoryFills[i],
                t,
              )!,
          ],
        );
}

extension CozyColorContext on BuildContext {
  CozyColors get cozyColors =>
      Theme.of(this).extension<CozyColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? CozyColors.dark
          : CozyColors.light);
}
