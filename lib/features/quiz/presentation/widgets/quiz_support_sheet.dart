import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';

class QuizSupportSheet extends StatelessWidget {
  const QuizSupportSheet({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (_) => const QuizSupportSheet(),
  );
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Support is here for you',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your answers suggest things may feel difficult right now. You can explore support resources or speak with a professional whenever you feel ready.',
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push(AppRouter.crisisHub);
            },
            child: const Text('View support resources'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("I'm okay right now"),
          ),
        ],
      ),
    ),
  );
}
