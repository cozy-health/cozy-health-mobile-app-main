import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/progress_track.dart';
import '../../domain/clinical_assessment.dart';
import '../widgets/clinical_disclaimer_sheet.dart';
import '../widgets/quiz_back_confirm_dialog.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../data/quiz_repository.dart';
import '../../../../core/services/feature_flags_service.dart';
import '../widgets/quiz_session_guard.dart';

class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({super.key, required this.extra, this.repository});
  final Map<String, dynamic> extra;
  final QuizRepository? repository;
  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen>
    with QuizSessionGuard<QuizTakingScreen> {
  static const _legacyQuestions = [
    'Little interest or pleasure in doing things?',
    'Feeling down, depressed, or hopeless?',
    'Trouble falling or staying asleep, or sleeping too much?',
  ];
  late final ClinicalAssessment? _assessment;
  late final List<int?> _answers;
  int _currentIndex = 0;
  bool _ready = false;
  bool _submitting = false;
  bool _invalidAssessment = false;
  String? _error;
  final String _attemptId = const Uuid().v4();
  List<String> get _questions => _assessment?.questions ?? _legacyQuestions;
  @override
  void initState() {
    super.initState();
    _assessment = widget.extra['definition'] is Map
        ? ClinicalAssessment.fromExtra(widget.extra)
        : null;
    _invalidAssessment =
        _assessment == null || !FeatureFlagsService.instance.isEnabled('quiz');
    _answers = List<int?>.filled(_questions.length, null);
    if (_invalidAssessment) {
      _error =
          'This assessment is not available. Please return to the assessment chooser.';
    } else if (_assessment == null) {
      _ready = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _acknowledge());
    }
  }

  Future<void> _acknowledge() async {
    try {
      final accepted = await ClinicalDisclaimerSheet.show(
        context,
        disclaimer: _assessment?.disclaimer,
      );
      if (!mounted) return;
      if (accepted == true) {
        setState(() {
          _ready = true;
          _error = null;
        });
      } else {
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not start the assessment. Please try again.',
        );
      }
    }
  }

  Future<void> _leave() async {
    if (!_ready || await QuizBackConfirmDialog.show(context) == true) {
      if (mounted) {
        setState(() => _ready = false);
        context.pop();
      }
    }
  }

  Future<void> _nextQuestion() async {
    if (!isQuizSessionActive) return;
    if (_answers[_currentIndex] == null || _submitting) return;
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      return;
    }
    final answers = _answers.cast<int>();
    final score =
        _assessment?.score(answers) ??
        answers.fold<int>(0, (sum, answer) => sum + answer);
    setState(() => _submitting = true);
    final assessment = _assessment!;
    final attempt = QuizAttempt(
      id: _attemptId,
      quizId: assessment.id,
      quizSlug: assessment.id,
      quizTitle: assessment.title,
      answers: answers,
      score: score,
      interpretation: assessment.severity(score),
      isCrisisFlagged: assessment.needsSupport(answers),
      completedAt: DateTime.now(),
      metadata: {
        'definition_version': assessment.definitionVersion,
        'validation_state': 'pending',
        'disclaimer_accepted': true,
        'maximum_score': assessment.maximumScore,
        'result_snapshot': {
          'definition': assessment.definition,
          'disclaimer': assessment.disclaimer,
          'recommendation': assessment.recommendation(score),
        },
      },
    );
    try {
      await (widget.repository ?? QuizRepository()).saveAttempt(attempt);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Could not save your answers. Please retry.';
        });
      }
      return;
    }
    if (!mounted) return;
    context.pushReplacement(
      AppRouter.quizResults,
      extra: {
        ...widget.extra,
        'score': score,
        'answers': answers,
        'attempt': attempt,
        'title': assessment.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) => !isQuizSessionActive
      ? const Scaffold(body: Center(child: Text('Sign in again to continue.')))
      : PopScope<Object?>(
          canPop: !_ready,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _leave();
          },
          child: Scaffold(
            body: SafeArea(
              child: !_ready
                  ? Center(
                      child: _error == null
                          ? const Text('Read the disclaimer to continue.')
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!),
                                if (!_invalidAssessment)
                                  TextButton(
                                    onPressed: _acknowledge,
                                    child: const Text('Retry'),
                                  ),
                                TextButton(
                                  onPressed: () => context.pop(),
                                  child: const Text('Back'),
                                ),
                              ],
                            ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Back',
                                onPressed: _currentIndex == 0
                                    ? _leave
                                    : () => setState(() => _currentIndex--),
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Expanded(
                                child: ProgressTrack(
                                  value:
                                      (_currentIndex + 1) / _questions.length,
                                  semanticLabel:
                                      'Question ${_currentIndex + 1} of ${_questions.length}',
                                ),
                              ),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: _leave,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            key: ValueKey(_currentIndex),
                            padding: const EdgeInsets.all(16),
                            children: [
                              Text(
                                'Question ${_currentIndex + 1} of ${_questions.length}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 16),
                              if (_assessment != null) ...[
                                Text(
                                  _assessment.questionTimeframe,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 20),
                              ],
                              Semantics(
                                header: true,
                                child: Text(
                                  _questions[_currentIndex],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                              ),
                              const SizedBox(height: 28),
                              for (
                                var index = 0;
                                index <
                                    (_assessment
                                            ?.options(_currentIndex)
                                            .length ??
                                        0);
                                index++
                              ) ...[
                                Semantics(
                                  button: true,
                                  selected:
                                      _answers[_currentIndex] ==
                                      _assessment!.options(
                                        _currentIndex,
                                      )[index]['id'],
                                  child: Material(
                                    color:
                                        _answers[_currentIndex] ==
                                            _assessment.options(
                                              _currentIndex,
                                            )[index]['id']
                                        ? Theme.of(context).colorScheme.primary
                                              .withValues(alpha: .08)
                                        : Theme.of(context).colorScheme.surface,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color:
                                            _answers[_currentIndex] ==
                                                _assessment.options(
                                                  _currentIndex,
                                                )[index]['id']
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(context).dividerColor,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () => setState(
                                        () => _answers[_currentIndex] =
                                            _assessment.options(
                                                  _currentIndex,
                                                )[index]['id']
                                                as int,
                                      ),
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 48,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _assessment.options(
                                                      _currentIndex,
                                                    )[index]['label']
                                                    as String,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _answers[_currentIndex] ==
                                                      _assessment.options(
                                                        _currentIndex,
                                                      )[index]['id']
                                                  ? Icons.radio_button_checked
                                                  : Icons
                                                        .radio_button_unchecked,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_error != null) Text(_error!),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                      _answers[_currentIndex] != null &&
                                          !_submitting
                                      ? _nextQuestion
                                      : null,
                                  child: Text(
                                    _currentIndex < _questions.length - 1
                                        ? 'Next'
                                        : 'Submit',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
}
