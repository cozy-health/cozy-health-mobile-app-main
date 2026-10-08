import 'package:flutter/material.dart';
import 'step_widgets.dart';

class FocusAreasStep extends StatelessWidget {
  const FocusAreasStep({
    super.key,
    required this.selected,
    required this.onToggle,
  });
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) => MultiSelectCards(
    title: 'What brings you here?',
    selected: selected,
    onToggle: onToggle,
    options: const {
      'Anxiety': Icons.air,
      'Low mood': Icons.cloud_outlined,
      'Stress': Icons.spa_outlined,
      'Sleep': Icons.bedtime_outlined,
      'Relationships': Icons.people_outline,
      'Self-growth': Icons.eco_outlined,
    },
  );
}
