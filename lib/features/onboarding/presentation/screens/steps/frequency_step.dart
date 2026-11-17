import 'package:flutter/material.dart';
import 'step_widgets.dart';

class FrequencyStep extends StatelessWidget {
  const FrequencyStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SingleSelectCards(
    title: 'How often do you want to check in?',
    selected: selected,
    onChanged: onChanged,
    options: const ['Daily', 'A few times a week', 'When I need it'],
  );
}
