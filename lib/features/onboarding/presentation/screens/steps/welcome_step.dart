import 'package:flutter/material.dart';
import 'step_widgets.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      Icon(
        Icons.spa_outlined,
        size: 120,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 32),
      const StepHeading(
        title: "Let's get to know you.",
        subtitle:
            'This helps us personalize your experience. It takes about a minute.',
      ),
    ],
  );
}
