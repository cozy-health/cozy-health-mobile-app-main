import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
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
    'angry',
    'sad',
    'good',
    'upset',
    'spectacular',
    'happy',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (final mood in moods)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                hint: 'Open mood check-in',
                button: true,
                selected: _selected == mood,
                child: Material(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.accentWarmYellowDark
                      : const Color(0xFFFEF4BE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selected == mood
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: _selected == mood ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      setState(() => _selected = mood);
                      await context.push<void>(
                        '${AppRouter.moodFeeling}?mood=$mood',
                      );
                      if (mounted) setState(() => _selected = null);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 71,
                            minHeight:
                                MediaQuery.textScalerOf(context).scale(12) > 18
                                ? 34
                                : 31,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/png/home_reference_$mood.png',
                                width: 31,
                                height: 31,
                                excludeFromSemantics: true,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${mood[0].toUpperCase()}${mood.substring(1)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: theme.brightness == Brightness.dark
                                      ? theme.colorScheme.onSurface
                                      : const Color(0xFF454545),
                                ),
                              ),
                            ],
                          ),
                        ),
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
