import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';

class MoodChipsRow extends StatefulWidget {
  const MoodChipsRow({super.key});
  @override
  State<MoodChipsRow> createState() => _MoodChipsRowState();
}

class _MoodChipsRowState extends State<MoodChipsRow> {
  String? _selected;
  static const moods = [
    'good',
    'calm',
    'okay',
    'anxious',
    'sad',
    'angry',
    'tired',
    'excited',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final mood in moods)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AnimatedScale(
                scale: _selected == mood ? 1.05 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                child: Material(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.accentWarmYellowDark
                      : AppColors.accentWarmYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _selected == mood
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      width: _selected == mood ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() => _selected = mood);
                      context.push('${AppRouter.moodFeeling}?mood=$mood');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (['good', 'sad', 'angry'].contains(mood))
                            SvgPicture.asset(
                              'assets/svg/$mood.svg',
                              width: 24,
                              height: 24,
                              excludeFromSemantics: true,
                            )
                          else
                            Text(
                              MoodEntry.moodEmojis[mood]!,
                              style: const TextStyle(fontSize: 23),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${mood[0].toUpperCase()}${mood.substring(1)}',
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
