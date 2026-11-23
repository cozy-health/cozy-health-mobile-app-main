import 'package:cozy_health/core/widgets/mood_artwork.dart';
import 'package:flutter/material.dart';

/// An expressive preview backed by the recording flow's five intensity levels.
class MoodIntensityControl extends StatelessWidget {
  const MoodIntensityControl({
    super.key,
    required this.value,
    required this.feeling,
    required this.mood,
    required this.onChanged,
  });

  final int value;
  final String feeling;
  final String mood;
  final ValueChanged<int> onChanged;

  static const _labels = [
    'Slight',
    'Mild',
    'Moderate',
    'Strong',
    'Very strong',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highContrast = MediaQuery.highContrastOf(context);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final label = _labels[value - 1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 156,
            child: Center(
              child: AnimatedScale(
                key: const ValueKey('intensity-mood-scale'),
                duration: duration,
                curve: Curves.easeOutCubic,
                scale: .85 + (value - 1) * .0375,
                child: MoodArtwork(mood: mood, size: 128),
              ),
            ),
          ),
        ),
        // The slider announces the same value together with the feeling.
        ExcludeSemantics(
          child: Text(
            '$label · $value/5',
            key: const ValueKey('intensity-value-label'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          label: '$feeling intensity',
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 12,
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.surfaceContainerHighest,
              thumbColor: highContrast ? scheme.onSurface : scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: .12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              activeTickMarkColor: scheme.onPrimary,
              inactiveTickMarkColor: scheme.onSurfaceVariant,
              tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              key: const ValueKey('recording-intensity-slider'),
              value: value.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              semanticFormatterCallback: (v) =>
                  '${_labels[v.round() - 1]}, ${v.round()} out of 5',
              onChanged: (v) {
                final next = v.round();
                if (next != value) onChanged(next);
              },
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Slight', style: theme.textTheme.bodySmall)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Very strong',
                textAlign: TextAlign.end,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
