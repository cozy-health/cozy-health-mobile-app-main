import 'package:flutter/material.dart';
import '../theme/cozy_colors.dart';
import 'app_pressable.dart';

/// Keep brand fills while using readable ink for small text and state glyphs.
Color wellnessAccentInk(BuildContext context, {Color? background}) {
  final c = Theme.of(context).colorScheme;
  return context.cozyColors.recording.controlColor(
    c.primary,
    background ?? c.surface,
    c.onSurface,
  );
}

/// Shared surfaces for the approved Home, Activity and care layouts.
class WellnessPanel extends StatelessWidget {
  const WellnessPanel({super.key, required this.child, this.tinted = false});
  final Widget child;
  final bool tinted;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w.gap),
      decoration: BoxDecoration(
        color: tinted ? w.accentPanel(c) : c.surface,
        borderRadius: BorderRadius.circular(w.radius),
        border: Border.all(color: c.outlineVariant),
      ),
      child: child,
    );
  }
}

class WellnessAction extends StatelessWidget {
  const WellnessAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.filled = false,
    this.selected,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool? selected;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    final foreground = onPressed == null
        ? c.onSurfaceVariant
        : filled
        ? c.onPrimary
        : c.onSurface;
    return AppPressable(
      label: label,
      selected: selected,
      onPressed: onPressed,
      child: Container(
        constraints: BoxConstraints(minHeight: w.touch),
        padding: EdgeInsets.symmetric(
          horizontal: w.contentGap,
          vertical: w.small,
        ),
        decoration: BoxDecoration(
          color: filled && onPressed != null ? c.primary : c.surface,
          border: Border.all(
            color: filled && onPressed != null ? c.primary : c.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(w.tileRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: foreground),
              SizedBox(width: w.small),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WellnessSegments extends StatelessWidget {
  const WellnessSegments({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    required this.keyPrefix,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final String keyPrefix;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    Widget item(int index) => AppPressable(
      key: ValueKey('$keyPrefix-$index'),
      selected: index == selected,
      onPressed: () => onSelected(index),
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minHeight: w.touch),
        padding: EdgeInsets.symmetric(horizontal: w.small, vertical: w.small),
        decoration: BoxDecoration(
          color: index == selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(w.tileRadius),
        ),
        child: Text(
          labels[index],
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: w.label,
            color: index == selected ? c.onPrimary : c.onSurface,
          ),
        ),
      ),
    );
    return Container(
      padding: EdgeInsets.all(w.tight),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(w.tileRadius + w.tight),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final widths = labels.map((label) {
            final painter = TextPainter(
              text: TextSpan(
                text: label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontSize: w.label),
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout();
            final width = painter.width + w.gap;
            painter.dispose();
            return width;
          }).toList();
          if (widths.reduce((a, b) => a > b ? a : b) * labels.length <=
              box.maxWidth) {
            return Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(child: item(i)),
              ],
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [for (var i = 0; i < labels.length; i++) item(i)],
            ),
          );
        },
      ),
    );
  }
}
