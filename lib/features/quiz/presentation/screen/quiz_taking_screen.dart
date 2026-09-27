import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../core/widgets/app_button.dart';

class QuizTakingScreen extends StatefulWidget {
  final String quizType;

  const QuizTakingScreen({
    super.key,
    required this.quizType,
  });

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int currentQuestionIndex = 0;
  String? selectedAnswer;

  // Sample questions - you can make this dynamic later
  final List<QuizQuestion> questions = [
    QuizQuestion(
      question: '1. How often do you experience sudden mood changes?',
      options: ['Rarely', 'Sometimes', 'Often', 'Always'],
    ),
    QuizQuestion(
      question: '2. Do you find it difficult to control your emotions in stressful situations?',
      options: ['Not at all', 'Occasionally', 'Frequently', 'Always'],
    ),
    QuizQuestion(
      question: '3. How would you rate your overall energy levels throughout the day?',
      options: ['Very Low', 'Low', 'Moderate', 'High'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Mental Health Quiz',
          style: AppTextStyles.heading2,
        ),
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

            // Progress indicator
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: AppColors.lightGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),

            5.sh,

            // Question number
            Text(
              'Question ${currentQuestionIndex + 1} of ${questions.length}',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            ),

            2.sh,

            // Question text
            Text(
              currentQuestion.question,
              style: AppTextStyles.heading1.copyWith(fontSize: 22),
            ),

            6.sh,

            // Answer options
            Column(
              children: currentQuestion.options.map((option) {
                final isSelected = selectedAnswer == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAnswer = option;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.midGrey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.body1.copyWith(
                              color: isSelected ? AppColors.white : AppColors.black,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.white : AppColors.midGrey,
                              width: 2,
                            ),
                            color: isSelected ? AppColors.white : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: AppColors.primary)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // Next button
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: AppButton(
                text: currentQuestionIndex == questions.length - 1 ? 'Finish Quiz' : 'Next',
                onPressed: selectedAnswer == null
                    ? null
                    : () {
                        if (currentQuestionIndex < questions.length - 1) {
                          setState(() {
                            currentQuestionIndex++;
                            selectedAnswer = null;
                          });
                        }  else {
  // Navigate to Quiz Results Screen
  context.push(
    AppRouter.quizResults,
    extra: widget.quizType,   // Pass the quiz title/type
  );
}
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;

  QuizQuestion({
    required this.question,
    required this.options,
  });
}