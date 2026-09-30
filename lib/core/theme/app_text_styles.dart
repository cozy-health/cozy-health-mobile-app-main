import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );

  static TextStyle get heading2 => GoogleFonts.outfit(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
  );

  static TextStyle get body1 => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );

  static TextStyle get body2 => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.grey,
  );

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
