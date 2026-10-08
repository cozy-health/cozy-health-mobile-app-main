import 'package:flutter/material.dart';

class StepHeading extends StatelessWidget {
  const StepHeading({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 16),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
      const SizedBox(height: 24),
    ],
  );
}

class MultiSelectCards extends StatelessWidget {
  const MultiSelectCards({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });
  final String title;
  final Map<String, IconData> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StepHeading(
        title: title,
        subtitle: 'Choose what feels relevant. You can select more than one.',
      ),
      for (final option in options.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Semantics(
            selected: selected.contains(option.key),
            button: true,
            child: OutlinedButton(
              onPressed: () => onToggle(option.key),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: selected.contains(option.key)
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(
                  color: selected.contains(option.key)
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(option.value),
                  const SizedBox(width: 16),
                  Expanded(child: Text(option.key)),
                  Icon(
                    selected.contains(option.key)
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class SingleSelectCards extends StatelessWidget {
  const SingleSelectCards({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StepHeading(title: title),
      RadioGroup<String>(
        groupValue: selected,
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        child: Column(
          children: [
            for (final option in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: selected == option
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Text(option),
                    value: option,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
