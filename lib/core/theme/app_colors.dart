import 'package:flutter/material.dart';

class AppColors {
  // Brand palette from the owner: blue, green, orange, and yellow.
  static const Color surfaceSubtle = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textTertiary = Color(0xFFA3A3A3);
  static const Color borderSubtle = Color(0xFFD4D4D4);
  static const Color borderDefault = Color(0xFFD4D4D4);
  static const Color accentWarmYellow = Color(0xFFFFFFFF);
  static const Color accentSage = Color(0xFFFFFFFF);
  static const Color accentPeach = Color(0xFFFFFFFF);
  static const Color accentBlush = Color(0xFFFFFFFF);
  static const Color accentSky = Color(0xFFFFFFFF);
  static const Color accentRose = Color(0xFFF25C05);
  static const Color accentTeal = Color(0xFFFFFFFF);

  // Neutral dark surfaces; brand accents stay identical in both modes.
  static const Color surfaceSubtleDark = Color(0xFF000000);
  static const Color textSecondaryDark = Color(0xFFB5B5B5);
  static const Color textTertiaryDark = Color(0xFFA3A3A3);
  static const Color borderSubtleDark = Color(0xFF404040);
  static const Color borderDefaultDark = Color(0xFF666666);
  static const Color accentWarmYellowDark = Color(0xFF000000);
  static const Color accentSageDark = Color(0xFF000000);
  static const Color accentPeachDark = Color(0xFF000000);
  static const Color accentBlushDark = Color(0xFF000000);
  static const Color accentSkyDark = Color(0xFF000000);
  static const Color accentRoseDark = Color(0xFFF25C05);
  static const Color accentTealDark = Color(0xFF000000);

  // Light theme
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color navBarLight = Color(0xFFFFFFFF);
  static const Color bottomSheetLight = Color(0xFFFFFFFF);
  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFF373737);
  static const Color textMutedLight = Color(0xFF737373);
  static const Color textSubtleLight = Color(0xFFA3A3A3);
  static const Color borderLight = Color(0xFFD4D4D4);
  static const Color borderStrongLight = Color(0xFFD4D4D4);

  // Dark theme
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF000000);
  static const Color surfaceElevatedDark = Color(0xFF000000);
  static const Color navBarDark = Color(0xFF000000);
  static const Color bottomSheetDark = Color(0xFF000000);
  static const Color dialogDark = Color(0xFF000000);
  static const Color textDark = Color(0xFFFAFAFA);
  static const Color textMutedDark = Color(0xFFB5B5B5);
  static const Color textSubtleDark = Color(0xFFA3A3A3);
  static const Color borderDark = Color(0xFF404040);
  static const Color borderStrongDark = Color(0xFF666666);

  // Shared accents
  static const Color primary = Color(0xFF0460D8);
  static const Color primaryDark = Color(0xFF0460D8);
  static const Color primaryHover = Color(0xFF0460D8);
  static const Color primarySubtle = Color(0x140460D8);
  static const Color primarySoft = Color(0x140460D8);
  static const Color success = Color(0xFF00BC4C);
  static const Color warning = Color(0xFFF2CB05);
  static const Color danger = Color(0xFFF25C05);
  static const Color warmYellow = Color(0xFFF2CB05);
  static const Color warmGreen = Color(0xFF00BC4C);
  static const Color warmOrange = Color(0xFFF25C05);

  // Legacy aliases retained while screens are migrated to theme tokens.
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = textMutedLight;
  static const Color lightGrey = Color(0xFFFAFAFA);
  static const Color midGrey = Color.fromARGB(255, 207, 207, 207);
  static const Color darkGrey = textLight;
  static const Color text = textLight;
  static const Color textMuted = textMutedLight;
  static const Color textSubtle = textSubtleLight;
  static const Color border = borderLight;
  static const Color borderStrong = Color(0xFFD4D4D4);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = surfaceElevatedLight;
  static const Color background = Color(0xFFFFFFFF);
  static const Color warmBackground = Color(0xFFFFFFFF);
  static const Color moodGood = Color(0xFF00BC4C);
  static const Color moodOkay = Color(0xFFF2CB05);
  static const Color moodLow = Color(0xFFF25C05);

  // Crisis theme
  static const Color crisisBg = Color(0xFFFFFFFF);
  static const Color crisisSurface = Color(0xFFFFFFFF);
  static const Color crisisText = Color(0xFF373737);
  static const Color crisisTextMuted = Color(0xFF737373);
  static const Color crisisPrimary = Color(0xFFF25C05);
  static const Color crisisPrimaryHover = Color(0xFFF25C05);
  static const Color crisisSubtle = Color(0xFFFFFFFF);
  static const Color crisisSafe = Color(0xFF00BC4C);
  static const Color crisisWarning = Color(0xFFF2CB05);
  static const Color crisisDanger = Color(0xFFF25C05);
  static const Color crisisTextOnDark = Color(0xFFFFFFFF);
  static const Color crisisBgDark = Color(0xFF000000);
  static const Color crisisSurfaceDark = Color(0xFF000000);
  static const Color crisisTextDark = Color(0xFFFAFAFA);
  static const Color crisisTextMutedDark = Color(0xFFB5B5B5);
  static const Color crisisSubtleDark = Color(0xFF000000);
  static const brandPalette = [primary, success, warmOrange, warmYellow];
  static Color resolveAccent(String? value) {
    final raw = value?.trim() ?? '';
    final parsed = raw.startsWith('#') && raw.length == 7
        ? int.tryParse('FF${raw.substring(1)}', radix: 16)
        : int.tryParse(raw);
    if (parsed == null) return primary;
    final color = Color(parsed);
    return brandPalette.contains(color) ? color : primary;
  }
}
