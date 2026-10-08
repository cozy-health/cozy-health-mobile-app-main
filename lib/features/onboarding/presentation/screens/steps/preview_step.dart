import 'package:flutter/material.dart';
import 'step_widgets.dart';

class PreviewStep extends StatelessWidget {
  const PreviewStep({
    super.key,
    required this.focusAreas,
    required this.challenges,
    required this.frequency,
    required this.onEdit,
  });
  final Set<String> focusAreas;
  final Set<String> challenges;
  final String frequency;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const StepHeading(title: "Here's what we'll focus on."),
      if (focusAreas.isNotEmpty) ...[
        const Text('Your focus areas'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: focusAreas.map((s) => Chip(label: Text(s))).toList(),
        ),
        const SizedBox(height: 24),
      ],
      if (challenges.isNotEmpty) ...[
        const Text('What you’re navigating'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: challenges.map((s) => Chip(label: Text(s))).toList(),
        ),
        const SizedBox(height: 24),
      ],
      if (focusAreas.isEmpty && challenges.isEmpty)
        const Text(
          'You can explore at your own pace. There’s room to figure things out as you go.',
        ),
      const SizedBox(height: 24),
      Text('Check-ins: $frequency'),
      const SizedBox(height: 24),
      TextButton(onPressed: onEdit, child: const Text('Edit preferences')),
    ],
  );
}
