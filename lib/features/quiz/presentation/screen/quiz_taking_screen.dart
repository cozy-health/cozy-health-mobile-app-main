import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/quiz_service.dart';

class QuizTakingScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  final String quizType;

  const QuizTakingScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.quizType,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  final QuizService _quizService = QuizService();

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  int currentQuestionIndex = 0;
  int? selectedOptionIndex;

  List<dynamic> questions = [];
  List<dynamic> options = [];
  final List<Map<String, int>> answers = [];

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final response = await _quizService.getQuiz(quizId: widget.quizId);
      final quiz = response['quiz'] as Map<String, dynamic>;

      setState(() {
        questions = quiz['questions'] as List<dynamic>? ?? [];
        options = quiz['options'] as List<dynamic>? ?? [];
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to load quiz.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _questionText(dynamic question, int index) {
    if (question is Map<String, dynamic>) {
      return question['question']?.toString() ??
          question['text']?.toString() ??
          'Question ${index + 1}';
    }

    return question.toString();
  }

  List<dynamic> _currentOptions() {
    final raw = options[currentQuestionIndex];

    if (raw is List) return raw;

    if (raw is Map<String, dynamic>) {
      final values = raw['options'];
      if (values is List) return values;
    }

    return [];
  }

  String _optionText(dynamic option) {
    if (option is Map<String, dynamic>) {
      return option['label']?.toString() ??
          option['text']?.toString() ??
          option['option']?.toString() ??
          '';
    }

    return option.toString();
  }

  Future<void> _nextOrSubmit() async {
    if (selectedOptionIndex == null) return;

    answers.removeWhere(
      (item) => item['question_index'] == currentQuestionIndex,
    );

    answers.add({
      'question_index': currentQuestionIndex,
      'option_index': selectedOptionIndex!,
    });

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
      });
      return;
    }

    setState(() => _submitting = true);

    try {
      final response = await _quizService.submitQuiz(
        quizId: widget.quizId,
        answers: answers,
      );

      final summary = response['summary'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      context.pushReplacement(
        AppRouter.quizResults,
        extra: {
          'title': summary['quiz_title']?.toString() ?? widget.quizTitle,
          'score': summary['score'] ?? 0,
          'total_questions': summary['total_questions'] ?? questions.length,
        },
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to submit quiz.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(backgroundColor: AppColors.white, elevation: 0),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Text(
              _error!,
              style: AppTextStyles.body1.copyWith(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(backgroundColor: AppColors.white, elevation: 0),
        body: Center(
          child: Text(
            'No questions available for this quiz.',
            style: AppTextStyles.body1,
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final currentOptions = _currentOptions();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.quizTitle, style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.black),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            4.sh,
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: AppColors.lightGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),
            5.sh,
            Text(
              'Question ${currentQuestionIndex + 1} of ${questions.length}',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            ),
            2.sh,
            Text(
              _questionText(currentQuestion, currentQuestionIndex),
              style: AppTextStyles.heading1.copyWith(fontSize: 22),
            ),
            6.sh,
            Column(
              children: List.generate(currentOptions.length, (index) {
                final option = currentOptions[index];
                final isSelected = selectedOptionIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedOptionIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.midGrey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _optionText(option),
                            style: AppTextStyles.body1.copyWith(
                              color:
                                  isSelected ? AppColors.white : AppColors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isSelected ? AppColors.white : AppColors.midGrey,
                              width: 2,
                            ),
                            color:
                                isSelected ? AppColors.white : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: AppColors.primary,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: AppButton(
                text: _submitting
                    ? 'Submitting...'
                    : currentQuestionIndex == questions.length - 1
                        ? 'Finish Quiz'
                        : 'Next',
                onPressed:
                    selectedOptionIndex == null || _submitting ? null : _nextOrSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}