import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/mood_category_grid.dart';

/// Home category shortcuts; selecting a category never selects a feeling.
class MoodChipsRow extends StatelessWidget {
  const MoodChipsRow({super.key});
  @override
  Widget build(BuildContext context) => MoodCategoryGrid(
    onSelected: (mood) {
      context.push<void>('${AppRouter.moodFeeling}?mood=$mood');
    },
  );
}
