import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'cozy_colors.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    extensions: const [CozyColors.light],
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surfaceLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textLight,
      onSurfaceVariant: AppColors.textMutedLight,
      outline: AppColors.borderStrongLight,
      outlineVariant: AppColors.borderLight,
      onError: Colors.white,
    ),
    textTheme: AppTextStyles.getTextTheme(Brightness.light),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBarLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMutedLight,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bottomSheetLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.dialogLight,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceElevatedLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.textLight,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      labelStyle: const TextStyle(color: AppColors.textLight),
      hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
      floatingLabelStyle: const TextStyle(color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    extensions: const [CozyColors.dark],
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      surface: AppColors.surfaceDark,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textMutedDark,
      outline: AppColors.borderStrongDark,
      outlineVariant: AppColors.borderDark,
      onError: Colors.white,
    ),
    textTheme: AppTextStyles.getTextTheme(Brightness.dark),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBarDark,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMutedDark,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bottomSheetDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.dialogDark,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
      space: 1,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surfaceElevatedDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevatedDark,
      contentTextStyle: TextStyle(color: AppColors.textDark),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      labelStyle: const TextStyle(color: AppColors.textDark),
      hintStyle: TextStyle(color: AppColors.textDark.withValues(alpha: 0.5)),
      floatingLabelStyle: const TextStyle(color: AppColors.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}
