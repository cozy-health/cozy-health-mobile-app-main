import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../data/quiz_repository.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/provider_share_confirm_dialog.dart';
import '../widgets/quiz_retake_confirm_dialog.dart';

class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const QuizResultScreen({super.key, required this.extra});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  @override
  void initState() {
    super.initState();
    // Check for crisis severity
    final score = widget.extra['score'] as int? ?? 0;
    final type = widget.extra['type'] as String? ?? 'wellness';
    
    // For mock PHQ-9 (max score 27, > 20 is severe)
    // We scaled our mock test to out of 9 (3 questions * 3 max), so severe would be > 6.
    if (type == 'clinical' && score >= 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Show crisis overlay
        context.push(AppRouter.crisisHub); // We can reuse the crisis flow entry point
      });
    }

    _saveAttempt();
  }

  void _saveAttempt() async {
    final title = widget.extra['title'] as String? ?? 'Quiz';
    final type = widget.extra['type'] as String? ?? 'wellness';
    final score = widget.extra['score'] as int? ?? 0;
    final answers = widget.extra['answers'] as List<int>? ?? [];
    
    final interpretation = _getInterpretation(score, type);
    final isCrisisFlagged = type == 'clinical' && score >= 6;

    final attempt = QuizAttempt(
      id: const Uuid().v4(),
      quizId: 'mock_${type}_id',
      quizSlug: type,
      quizTitle: title,
      answers: answers,
      score: score,
      interpretation: interpretation,
      isCrisisFlagged: isCrisisFlagged,
      completedAt: DateTime.now(),
    );

    await QuizRepository().saveAttempt(attempt);
  }

  String _getInterpretation(int score, String type) {
    if (type != 'clinical') return 'Great job checking in with yourself!';
    if (score >= 6) return 'Your responses suggest you\'re going through a really hard time. A professional can help. Would you like resources?';
    if (score >= 4) return 'Your responses suggest you are experiencing some moderate challenges.';
    return 'Your responses suggest some low moments lately. Small steps matter.';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.extra['title'] as String? ?? 'Quiz Result';
    final type = widget.extra['type'] as String? ?? 'wellness';
    final score = widget.extra['score'] as int? ?? 0;
    final maxScore = type == 'clinical' ? 9 : 3; // mock scale
    final interpretation = _getInterpretation(score, type);

    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.text),
          onPressed: () => context.push(AppRouter.quizSelection), // Go back to selection
        ),
        title: Text('Results', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: AppTextStyles.heading2.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Animated Score
              if (reduceMotion)
                Text(
                  '$score',
                  style: AppTextStyles.heading1.copyWith(fontSize: 72, color: Theme.of(context).colorScheme.primary),
                  textAlign: TextAlign.center,
                )
              else
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: score),
                  duration: const Duration(seconds: 1),
                  builder: (context, value, child) {
                    return Text(
                      '$value',
                      style: AppTextStyles.heading1.copyWith(fontSize: 72, color: Theme.of(context).colorScheme.primary),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                
              Text(
                'out of $maxScore',
                style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  interpretation,
                  style: AppTextStyles.body1.copyWith(color: AppColors.text, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              
              // Breakdown
              Text('Breakdown', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildBreakdownRow('Little interest or pleasure...', score > 2 ? 'Nearly every day' : 'Not at all'),
              const SizedBox(height: 12),
              _buildBreakdownRow('Feeling down...', score > 2 ? 'More than half the days' : 'Several days'),
              
              const SizedBox(height: 48),
              
              AppButton(
                text: 'Done',
                onPressed: () => context.push(AppRouter.quizSelection),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Share with provider',
                isOutlined: true,
                onPressed: () async {
                  final result = await ProviderShareConfirmDialog.show(context);
                  if (result == true) {
                    // Logic to share
                  }
                },
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final result = await QuizRetakeConfirmDialog.show(context);
                    if (result == 'retake') {
                      if (context.mounted) context.pushReplacement(AppRouter.quizTaking, extra: widget.extra);
                    }
                  },
                  child: Text('Retake Quiz', style: AppTextStyles.body1.copyWith(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: AppTextStyles.body2.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(answer, style: AppTextStyles.body1.copyWith(color: AppColors.text, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
