import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'cozy_colors.dart';

class AppTheme {
  /// Derive after accent selection, keeping semantic foregrounds readable.
  static ThemeData highContrast(ThemeData base) {
    final dark = base.brightness == Brightness.dark;
    final surface = dark ? Colors.black : Colors.white;
    final foreground = dark ? Colors.white : Colors.black;
    Color readable(Color color) {
      final backdrop = surface.computeLuminance();
      double ratio(Color candidate) {
        final value = candidate.computeLuminance();
        return value > backdrop
            ? (value + .05) / (backdrop + .05)
            : (backdrop + .05) / (value + .05);
      }

      var adjusted = color;
      for (var step = 0; step < 100 && ratio(adjusted) < 4.5; step++) {
        adjusted = Color.lerp(adjusted, foreground, .08)!;
      }
      return adjusted;
    }

    final primary = readable(base.colorScheme.primary);
    final secondary = readable(base.colorScheme.secondary);
    final tertiary = readable(base.colorScheme.tertiary);
    final error = readable(base.colorScheme.error);
    Color onColor(Color color) =>
        color.computeLuminance() > .179 ? Colors.black : Colors.white;
    final onPrimary = primary.computeLuminance() > .179
        ? Colors.black
        : Colors.white;
    final scheme = base.colorScheme.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: surface,
      onPrimaryContainer: primary,
      secondary: secondary,
      onSecondary: onColor(secondary),
      secondaryContainer: surface,
      onSecondaryContainer: foreground,
      tertiary: tertiary,
      onTertiary: onColor(tertiary),
      tertiaryContainer: surface,
      onTertiaryContainer: foreground,
      surface: surface,
      surfaceDim: surface,
      surfaceBright: surface,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,
      onSurface: foreground,
      onSurfaceVariant: foreground,
      outline: foreground,
      outlineVariant: foreground,
      error: error,
      onError: onColor(error),
      errorContainer: surface,
      onErrorContainer: foreground,
    );
    final extension = base.extension<CozyColors>() ?? CozyColors.light;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: foreground, width: 2),
    );
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? foreground.withValues(alpha: .6)
            : primary,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? surface : onPrimary,
      ),
    );
    return base.copyWith(
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      disabledColor: foreground.withValues(alpha: .6),
      dividerColor: foreground,
      dividerTheme: DividerThemeData(color: foreground, thickness: 2),
      textTheme: base.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: onPrimary,
        displayColor: onPrimary,
      ),
      iconTheme: base.iconTheme.copyWith(color: foreground),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: surface,
        foregroundColor: foreground,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: base.dialogTheme.copyWith(backgroundColor: surface),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: surface,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: foreground,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: foreground),
        actionTextColor: primary,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: surface,
        labelStyle: TextStyle(color: foreground),
        hintStyle: TextStyle(color: foreground),
        floatingLabelStyle: TextStyle(color: primary),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            base.elevatedButtonTheme.style?.merge(buttonStyle) ?? buttonStyle,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: base.filledButtonTheme.style?.merge(buttonStyle) ?? buttonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: surface,
        labelStyle: TextStyle(color: foreground),
        side: BorderSide(color: foreground, width: 2),
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: primary,
        unselectedLabelColor: foreground,
        indicatorColor: primary,
      ),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: primary,
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: primary,
        thumbColor: primary,
      ),
      checkboxTheme: base.checkboxTheme.copyWith(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        checkColor: WidgetStateProperty.all(onPrimary),
      ),
      radioTheme: base.radioTheme.copyWith(
        fillColor: WidgetStateProperty.all(primary),
      ),
      switchTheme: base.switchTheme.copyWith(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : surface,
        ),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? onPrimary : foreground,
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: primary,
        foregroundColor: onPrimary,
      ),
      extensions: [
        for (final value in base.extensions.values)
          if (value is! CozyColors) value,
        extension.copyWith(
          calendarBg: surface,
          journalingBg: surface,
          quizBg: surface,
          crisis: readable(extension.crisis),
          triggerLow: readable(extension.triggerLow),
          triggerMed: readable(extension.triggerMed),
          triggerHigh: readable(extension.triggerHigh),
        ),
      ],
    );
  }

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
      primary: AppColors.primaryDark,
      surface: AppColors.surfaceDark,
      error: AppColors.danger,
      onPrimary: AppColors.backgroundDark,
      onSurface: AppColors.textDark,
      onSurfaceVariant: AppColors.textMutedDark,
      outline: AppColors.borderStrongDark,
      outlineVariant: AppColors.borderDark,
      onError: Colors.white,
    ),
    textTheme: AppTextStyles.getTextTheme(Brightness.dark),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBarDark,
      selectedItemColor: AppColors.primaryDark,
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
      floatingLabelStyle: const TextStyle(color: AppColors.primaryDark),
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
