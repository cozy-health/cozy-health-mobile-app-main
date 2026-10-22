import 'package:flutter/material.dart';

/// Scoped Home and Feeling design values; does not recolour other app surfaces.
@immutable
class WellnessTokens {
  const WellnessTokens();
  double get page => 20;
  double get gap => 16;
  double get small => 8;
  double get tight => 4;
  double get contentGap => 12;
  double get sectionSpacing => 20;
  double get section => 24;
  double get radius => 24;
  double get tileRadius => 16;
  double get heading => 28;
  double get label => 14;
  double get streakIcon => 40;
  double get face => 48;
  double get compactFace => 40;
  double get tileHeight => 96;
  double get compactTileHeight => 76;
  double get touch => 48;
  double get floatingSize => 56;
  double get floatingGap => 16;
  double get floatingInset => 16;
  double get floatingClearance =>
      floatingInset + floatingSize * 2 + floatingGap + small;
  double get breakpoint => 280;
  Duration get transition => const Duration(milliseconds: 180);
  Color canvas(Brightness brightness, bool contrast) => contrast
      ? brightness == Brightness.dark
            ? Colors.black
            : Colors.white
      : brightness == Brightness.dark
      ? const Color(0xFF0B0D0D)
      : const Color(0xFFFAF8F3);

  /// Shared check-in/reset fill derives from the live user accent.
  Color accentPanel(ColorScheme scheme) => Color.alphaBlend(
    scheme.primary.withValues(
      alpha: scheme.brightness == Brightness.dark ? .20 : .12,
    ),
    scheme.surface,
  );
  Color reminder(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xFF302810)
      : const Color(0xFFFFF3CE);
}
