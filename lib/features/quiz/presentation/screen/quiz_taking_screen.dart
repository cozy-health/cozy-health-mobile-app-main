import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/progress_track.dart';
import '../../domain/clinical_assessment.dart';
import '../widgets/clinical_disclaimer_sheet.dart';
import '../widgets/quiz_back_confirm_dialog.dart';

class QuizTakingScreen extends StatefulWidget {
  const QuizTakingScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
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
  List<String> get _questions => _assessment?.questions ?? _legacyQuestions;
  @override
  void initState() {
    super.initState();
    _assessment = ClinicalAssessment.find(widget.extra['id'] as String?);
    _invalidAssessment =
        _assessment == null &&
        !ClinicalAssessment.legacyAssessments.containsKey(widget.extra['id']);
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
      final accepted = await ClinicalDisclaimerSheet.show(context);
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

  void _nextQuestion() {
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
    context.pushReplacement(
      AppRouter.quizResults,
      extra: {
        ...widget.extra,
        'score': score,
        'answers': answers,
        if (_assessment != null) 'title': _assessment.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_ready,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      body: SafeArea(
        child: !_ready
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
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
                            value: (_currentIndex + 1) / _questions.length,
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
                            ClinicalAssessment.timeframe,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                        ],
                        Semantics(
                          header: true,
                          child: Text(
                            _questions[_currentIndex],
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 28),
                        for (
                          var index = 0;
                          index < ClinicalAssessment.answerLabels.length;
                          index++
                        ) ...[
                          Semantics(
                            button: true,
                            selected: _answers[_currentIndex] == index,
                            child: Material(
                              color: _answers[_currentIndex] == index
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: .08)
                                  : Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _answers[_currentIndex] == index
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => setState(
                                  () => _answers[_currentIndex] = index,
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
                                          ClinicalAssessment
                                              .answerLabels[index],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _answers[_currentIndex] == index
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
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
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _answers[_currentIndex] != null && !_submitting
                            ? _nextQuestion
                            : null,
                        child: Text(
                          _currentIndex < _questions.length - 1
                              ? 'Next'
                              : 'Submit',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}
