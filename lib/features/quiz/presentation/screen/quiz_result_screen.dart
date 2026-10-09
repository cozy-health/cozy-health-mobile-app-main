import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../../core/routing/app_router.dart';
import '../../data/quiz_repository.dart';
import '../../domain/clinical_assessment.dart';
import '../widgets/quiz_result_content.dart';
import '../widgets/provider_share_confirm_dialog.dart';
import '../widgets/quiz_retake_confirm_dialog.dart';
import '../widgets/quiz_support_sheet.dart';

class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  QuizAttempt? _attempt;
  bool _saved = false;
  bool _saving = false;
  bool _sharing = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final assessment = ClinicalAssessment.find(widget.extra['id'] as String?);
    try {
      if (assessment == null && widget.extra['type'] == 'clinical') {
        throw ArgumentError('Unknown clinical assessment');
      }
      final answers = List<int>.from(
        widget.extra['answers'] as List? ?? const [],
      );
      final score =
          assessment?.score(answers) ?? widget.extra['score'] as int? ?? 0;
      final severity =
          assessment?.severity(score) ?? 'Great job checking in with yourself!';
      _attempt = QuizAttempt(
        id: const Uuid().v4(),
        quizId: assessment?.id ?? widget.extra['id'] as String? ?? 'legacy',
        quizSlug: assessment?.id ?? widget.extra['id'] as String? ?? 'legacy',
        quizTitle:
            assessment?.title ?? widget.extra['title'] as String? ?? 'Quiz',
        answers: answers,
        score: score,
        interpretation: severity,
        severityLabel: assessment != null ? severity : '',
        isCrisisFlagged: assessment?.needsSupport(answers) ?? false,
        completedAt: DateTime.now(),
      );
      _saveAttempt();
      if (_attempt!.isCrisisFlagged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) QuizSupportSheet.show(context);
        });
      }
    } catch (_) {
      _error =
          'Your assessment is incomplete. Please return and finish all questions.';
    }
  }

  Future<void> _saveAttempt() async {
    if (_attempt == null || _saving || _saved) return;
    _saving = true;
    try {
      await QuizRepository().saveAttempt(_attempt!);
      if (mounted) {
        setState(() {
          _saved = true;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save your result. Please retry before leaving.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Results'),
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Close results',
        onPressed: () => context.push(AppRouter.quizSelection),
        icon: const Icon(Icons.close),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_attempt != null) QuizResultContent(attempt: _attempt!),
          if (_error != null) ...[
            Text(_error!, textAlign: TextAlign.center),
            if (_attempt != null)
              TextButton(
                onPressed: _saving ? null : _saveAttempt,
                child: const Text('Retry save'),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.push(AppRouter.quizSelection),
            child: const Text('Done'),
          ),
          if (_attempt != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: !_saved || _sharing
                  ? null
                  : () async {
                      setState(() => _sharing = true);
                      await QuizProviderSharing.share(context);
                      if (mounted) setState(() => _sharing = false);
                    },
              child: Text(_sharing ? 'Sharing…' : 'Share with provider'),
            ),
            TextButton(
              onPressed: () async {
                if (await QuizRetakeConfirmDialog.show(context) == 'retake' &&
                    context.mounted) {
                  context.pushReplacement(
                    AppRouter.quizTaking,
                    extra: widget.extra,
                  );
                }
              },
              child: const Text('Retake Quiz'),
            ),
          ],
        ],
      ),
    ),
  );
}
