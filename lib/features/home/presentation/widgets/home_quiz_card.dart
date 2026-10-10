import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';

class HomeQuizCard extends StatelessWidget {
  const HomeQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final textColor = dark
        ? theme.colorScheme.onSurface
        : const Color(0xFF555965);
    final art = Image.asset(
      'assets/png/home_quiz_brain.png',
      width: 146.59,
      height: 113,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    final copy = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mental Health Quiz',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Take a quick self-assessment to gain insights into your mental well-being.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.3,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push(AppRouter.quizSelection),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0066FF),
            side: const BorderSide(color: Color(0xFF0066FF)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            minimumSize: const Size(0, 33),
            tapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Start Quiz',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF0066FF),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ],
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 179),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark
            ? theme.colorScheme.surfaceContainer
            : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 290 ||
              MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [art, const SizedBox(height: 12), copy],
            );
          }
          return Row(
            children: [
              art,
              const SizedBox(width: 16),
              Expanded(child: copy),
            ],
          );
        },
      ),
    );
  }
}
