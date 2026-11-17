import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Figma role mapping uses the existing Outfit scale, not outline heights.
  // Screen headings -> h1/h2; card and quiz headings -> h3.
  static TextStyle get display =>
      GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold);
  static TextStyle get h1 => heading1;
  static TextStyle get h2 => heading2;
  static TextStyle get h3 => heading3;

  // Editor/body copy -> bodyLarge; descriptions/questions/answers -> body.
  static TextStyle get bodyLarge => body1;
  static TextStyle get body => body2;

  // Dates, metadata, chart labels and weekdays share the next Outfit step.
  // Colors are supplied by the consuming widget's active theme.
  static TextStyle get bodySmall =>
      GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.normal);
  static TextStyle get caption => bodySmall;

  // Author names, chips, counters and emphasized questions -> label.
  static TextStyle get label => body.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get button => buttonText;
  // Compact card actions and secondary actions -> buttonSmall.
  static TextStyle get buttonSmall =>
      body.copyWith(fontWeight: FontWeight.w600);

  static TextTheme getTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.dark
        ? AppColors.textDark
        : AppColors.textLight;
    final mutedColor = brightness == Brightness.dark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return GoogleFonts.outfitTextTheme()
        .apply(bodyColor: textColor, displayColor: textColor)
        .copyWith(
          bodySmall: GoogleFonts.outfit(fontSize: 12, color: mutedColor),
          displayLarge: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          headlineLarge: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          headlineMedium: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          headlineSmall: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          bodyLarge: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
          bodyMedium: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: mutedColor,
          ),
          labelLarge: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        );
  }

  static TextStyle get heading1 =>
      GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold);

  static TextStyle get heading2 =>
      GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600);

  static TextStyle get heading3 =>
      GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600);

  static TextStyle get body1 =>
      GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal);

  static TextStyle get body2 =>
      GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal);

  static TextStyle get buttonText => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle get linkText => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}
