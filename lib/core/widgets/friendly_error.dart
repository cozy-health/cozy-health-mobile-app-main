import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';

class FriendlyError extends StatelessWidget {
  const FriendlyError({
    super.key,
    this.title = "We couldn't load your data.",
    this.message = 'Check your connection and try again.',
    this.onRetry,
    this.failureCount = 1,
  });
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final int failureCount;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(message),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        if (failureCount >= 3)
          TextButton(
            onPressed: () => context.push(AppRouter.helpSupport),
            child: const Text('Help & Support'),
          ),
      ],
    ),
  );
}
