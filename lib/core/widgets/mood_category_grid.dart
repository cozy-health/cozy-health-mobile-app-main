import 'package:flutter/material.dart';
import '../theme/cozy_colors.dart';
import '../utils/motion.dart';
import 'app_pressable.dart';
import 'mood_artwork.dart';

/// The same original category characters on Home and the Feeling switcher.
class MoodCategoryGrid extends StatelessWidget {
  const MoodCategoryGrid({
    super.key,
    required this.onSelected,
    this.selected,
    this.compact = false,
  });
  static const moods = [
    'angry',
    'sad',
    'good',
    'upset',
    'spectacular',
    'happy',
  ];
  final ValueChanged<String> onSelected;
  final String? selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final t = context.cozyColors.wellness;
    final contrast = MediaQuery.highContrastOf(context);
    final marker = context.cozyColors.recording.controlColor(
      scheme.primary,
      scheme.surface,
      scheme.onSurface,
      minimumContrast: 3,
    );
    return LayoutBuilder(
      builder: (context, box) {
        final columns =
            box.maxWidth < t.breakpoint ||
                MediaQuery.textScalerOf(context).scale(t.label) > 20
            ? 2
            : 3;
        final width = (box.maxWidth - t.small * (columns - 1)) / columns;
        return Wrap(
          spacing: t.small,
          runSpacing: t.small,
          children: [
            for (final mood in moods)
              SizedBox(
                width: width,
                child: AppPressable(
                  key: ValueKey('mood-category-$mood'),
                  label: '${mood[0].toUpperCase()}${mood.substring(1)}',
                  selected: selected == mood,
                  onPressed: () => onSelected(mood),
                  child: AnimatedContainer(
                    duration: motionDuration(context, t.transition),
                    constraints: BoxConstraints(
                      minHeight: compact ? t.compactTileHeight : t.tileHeight,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: t.small / 2,
                      vertical: t.small,
                    ),
                    decoration: BoxDecoration(
                      color: selected == mood && !contrast
                          ? Color.alphaBlend(
                              scheme.primary.withValues(alpha: .08),
                              scheme.surface,
                            )
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(t.tileRadius),
                      border: Border.all(
                        color: selected == mood
                            ? marker
                            : contrast
                            ? scheme.onSurface
                            : scheme.outline,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MoodArtwork(
                          mood: mood,
                          size: compact ? t.compactFace : t.face,
                        ),
                        SizedBox(height: t.small),
                        Text(
                          '${mood[0].toUpperCase()}${mood.substring(1)}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: t.label,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
