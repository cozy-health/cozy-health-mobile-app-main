import 'package:flutter/material.dart';
import 'step_widgets.dart';

class ChallengesStep extends StatelessWidget {
  const ChallengesStep({
    super.key,
    required this.selected,
    required this.onToggle,
  });
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) => MultiSelectCards(
    title: 'What are you struggling with right now?',
    selected: selected,
    onToggle: onToggle,
    options: const {
      'Work': Icons.work_outline,
      'School': Icons.school_outlined,
      'Family': Icons.home_outlined,
      'Health': Icons.favorite_border,
      'Money': Icons.account_balance_wallet_outlined,
      'Loneliness': Icons.person_outline,
    },
  );
}
