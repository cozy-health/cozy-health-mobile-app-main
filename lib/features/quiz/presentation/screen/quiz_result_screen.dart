import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/quiz_repository.dart';
import '../widgets/quiz_result_content.dart';
import '../widgets/quiz_share_actions.dart';
import '../widgets/quiz_support_sheet.dart';
import '../widgets/quiz_session_guard.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with QuizSessionGuard<QuizResultScreen> {
  bool _supportShown = false;
  void _support(QuizAttempt? attempt) {
    if (attempt?.isCrisisFlagged != true ||
        _supportShown ||
        !isQuizSessionActive) {
      return;
    }
    _supportShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && isQuizSessionActive) QuizSupportSheet.show(context);
    });
  }

  @override
  void initState() {
    super.initState();
    final attempt = widget.extra['attempt'] as QuizAttempt?;
    _support(attempt);
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.extra['attempt'] as QuizAttempt?;
    if (saved == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(
          child: Text('Finish an assessment to view your saved result.'),
        ),
      );
    }
    return StreamBuilder<List<QuizAttempt>>(
      stream: QuizRepository().watchAttempts(),
      initialData: LocalDbService().getAllQuizAttempts(),
      builder: (context, snapshot) {
        final found = snapshot.data?.where((a) => a.id == saved.id).firstOrNull;
        if (!isQuizSessionActive || found == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Results')),
            body: const Center(
              child: Text('This result is no longer available.'),
            ),
          );
        }
        final attempt = found;
        _support(attempt);
        return Scaffold(
          appBar: AppBar(title: const Text('Results')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                QuizResultContent(attempt: attempt),
                const SizedBox(height: 24),
                QuizShareActions(
                  key: ValueKey(attempt.validationState),
                  attempt: attempt,
                ),
                FilledButton(
                  onPressed: () => context.go('/quiz-selection'),
                  child: const Text('Done'),
                ),
                TextButton(
                  onPressed: () async {
                    final date = attempt.completedAt
                        .toLocal()
                        .toString()
                        .split(' ')
                        .first;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        scrollable: true,
                        title: const Text('Retake assessment?'),
                        content: Text(
                          'You last completed this assessment on $date. Start a new attempt?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Retake'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    final catalog = await QuizRepository().catalog();
                    final assessment = catalog
                        .where((a) => a.id == attempt.quizSlug)
                        .firstOrNull;
                    if (context.mounted && assessment != null) {
                      context.pushReplacement(
                        '/quiz-taking',
                        extra: {
                          'id': assessment.id,
                          'definition': assessment.definition,
                        },
                      );
                    }
                  },
                  child: const Text('Retake assessment'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
