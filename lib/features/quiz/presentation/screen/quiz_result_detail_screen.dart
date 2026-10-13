import 'package:flutter/material.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/quiz_repository.dart';
import '../widgets/quiz_result_content.dart';
import '../widgets/quiz_share_actions.dart';
import '../widgets/quiz_session_guard.dart';

class QuizResultDetailScreen extends StatefulWidget {
  const QuizResultDetailScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  State<QuizResultDetailScreen> createState() => _QuizResultDetailScreenState();
}

class _QuizResultDetailScreenState extends State<QuizResultDetailScreen>
    with QuizSessionGuard<QuizResultDetailScreen> {
  @override
  void initState() {
    super.initState();
    QuizRepository().fetchAttempts();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.extra['attempt'] as QuizAttempt?;
    final id = widget.extra['id'] as String? ?? initial?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Past result')),
      body: StreamBuilder<List<QuizAttempt>>(
        stream: QuizRepository().watchAttempts(),
        initialData: LocalDbService().getAllQuizAttempts(),
        builder: (context, snapshot) {
          final attempt = snapshot.data?.where((a) => a.id == id).firstOrNull;
          if (attempt == null || !isQuizSessionActive) {
            return const Center(child: Text('This result is not available.'));
          }
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                QuizResultContent(attempt: attempt),
                QuizShareActions(
                  key: ValueKey(attempt.validationState),
                  attempt: attempt,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
