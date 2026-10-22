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
    this.recording = const MoodRecordingTokens(),
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
  final MoodRecordingTokens recording;

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
    MoodRecordingTokens? recording,
  }) => CozyColors(
    crisis: crisis ?? this.crisis,
    calendarBg: calendarBg ?? this.calendarBg,
    journalingBg: journalingBg ?? this.journalingBg,
    quizBg: quizBg ?? this.quizBg,
    triggerLow: triggerLow ?? this.triggerLow,
    triggerMed: triggerMed ?? this.triggerMed,
    triggerHigh: triggerHigh ?? this.triggerHigh,
    recording: recording ?? this.recording,
    recordingCategoryFills:
        recordingCategoryFills ?? this.recordingCategoryFills,
  );

  @override
  CozyColors lerp(covariant CozyColors? other, double t) => other == null
      ? this
      : CozyColors(
          recording: recording,
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

/// Layout and interaction values shared by the scoped recording redesign.
@immutable
class MoodRecordingTokens {
  const MoodRecordingTokens();

  /// Control text and state indicators may adapt; illustration inks never do.
  Color controlColor(
    Color preferred,
    Color background,
    Color fallback, {
    double minimumContrast = 4.5,
  }) => contrastRatio(preferred, background) >= minimumContrast
      ? preferred
      : fallback;

  double contrastRatio(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    return first > second
        ? (first + .05) / (second + .05)
        : (second + .05) / (first + .05);
  }

  /// Prefer the category surface, using the existing neutral surface only when
  /// it improves a faint illustration without changing its colour or geometry.
  Color choiceSurface(Color categoryFill, Color ink, Color surface) =>
      contrastRatio(ink, categoryFill) < 3 &&
          contrastRatio(ink, surface) > contrastRatio(ink, categoryFill)
      ? surface
      : categoryFill;

  double get tiny => 4;
  double get small => 8;
  double get medium => 12;
  double get large => 16;
  double get page => 20;
  double get section => 24;
  double get touch => 48;
  double get buttonHeight => 52;
  double get controlRadius => 14;
  double get panelRadius => 16;
  double get border => 1;
  double get selectedBorder => 2;
  double get contentWidth => 560;
  double get headingSize => 26;
  double get bodySize => 14;
  double get twoColumnWidth => 300;
  double get singleColumnTextSize => 22;
  double get previewSize => 144;
  double get faceSize => 36;
  double get iconSize => 22;
  double get dotSize => 10;
  double get pressScale => .98;
  Duration get pressDuration => const Duration(milliseconds: 90);
  Duration get transitionDuration => const Duration(milliseconds: 200);
  List<Color> get categoryInks => const [
    Color(0xFF00A642),
    Color(0xFFF25C05),
    Color(0xFF0460D8),
    Color(0xFFF97066),
    Color(0xFFF04D6E),
    Color(0xFF00A0A6),
  ];
}

extension CozyColorContext on BuildContext {
  CozyColors get cozyColors =>
      Theme.of(this).extension<CozyColors>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? CozyColors.dark
          : CozyColors.light);
}
