import 'package:flutter/material.dart';
import 'step_widgets.dart';

class AttributionStep extends StatelessWidget {
  const AttributionStep({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final String? selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SingleSelectCards(
    title: 'How did you hear about us?',
    selected: selected,
    onChanged: onChanged,
    options: const [
      'Friend',
      'App Store',
      'Social',
      'Search',
      'Other',
      'Prefer not to say',
    ],
  );
}
