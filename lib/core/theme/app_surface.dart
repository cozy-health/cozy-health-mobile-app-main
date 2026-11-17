import 'package:flutter/material.dart';

/// Shared boundary for custom cards and overlays, including high contrast.
class AppSurface {
  static Color tint(BuildContext context, Color color) {
    final theme = Theme.of(context);
    return MediaQuery.highContrastOf(context)
        ? theme.colorScheme.surface
        : Color.alphaBlend(color, theme.colorScheme.surface);
  }

  static BorderSide side(BuildContext context, {Color? color}) {
    final outline = Theme.of(context).colorScheme.outline;
    final contrast = MediaQuery.highContrastOf(context);
    return BorderSide(
      color: contrast || color == null
          ? outline
          : Color.alphaBlend(color, outline),
      width: contrast ? 2 : 1,
    );
  }

  static Border border(BuildContext context) =>
      Border.fromBorderSide(side(context));

  static RoundedRectangleBorder shape(
    BuildContext context,
    BorderRadius radius,
  ) => RoundedRectangleBorder(borderRadius: radius, side: side(context));
}
