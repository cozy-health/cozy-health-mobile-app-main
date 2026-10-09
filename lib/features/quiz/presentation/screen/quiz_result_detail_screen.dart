import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../widgets/provider_share_confirm_dialog.dart';
import '../widgets/quiz_result_content.dart';

class QuizResultDetailScreen extends StatelessWidget {
  const QuizResultDetailScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  Widget build(BuildContext context) {
    final attempt = extra['attempt'] as QuizAttempt?;
    if (attempt == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Your result is not available yet. Please return to your assessments.',
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(DateFormat('MMM d, yyyy').format(attempt.completedAt)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            QuizResultContent(attempt: attempt),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => QuizProviderSharing.share(context),
              child: const Text('Share with provider'),
            ),
          ],
        ),
      ),
    );
  }
}
