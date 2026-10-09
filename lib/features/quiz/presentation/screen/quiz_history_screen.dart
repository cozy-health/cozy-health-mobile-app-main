import '../../../../core/services/user_data_fetcher.dart';
import '../../../../core/services/local_db_service.dart';
import 'package:cozy_health/core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../data/quiz_repository.dart';
import '../../domain/clinical_assessment.dart';
import 'package:intl/intl.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Quiz History', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<List<QuizAttempt>>(
          stream: QuizRepository().watchAttempts(),
          initialData: LocalDbService().getAllQuizAttempts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const ListSkeleton();
            }

            final attempts = [...?snapshot.data];
            if (attempts.isEmpty) {
              return EmptyState(
                onOfflineRetry: () => UserDataFetcher().fetchQuizAttempts(),
                icon: Icons.history,
                title: 'Your results will appear here.',
                primaryCtaLabel: 'Explore assessments',
                onPrimaryCta: () => context.push(AppRouter.quizSelection),
              );
            }
            attempts.sort(
              (a, b) => b.completedAt.compareTo(a.completedAt),
            ); // latest first

            // Keep every attempt in history. Trend each real instrument separately;
            // their raw scores use different scales. Legacy results remain below.
            final trends = {
              for (final assessment in ClinicalAssessment.all)
                assessment.id: attempts.reversed
                    .where(
                      (attempt) =>
                          attempt.assessmentId == assessment.id &&
                          attempt.answers.length == assessment.questions.length,
                    )
                    .map((attempt) => attempt.score.toDouble())
                    .toList(),
            };

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Score Trend Chart
                  for (final assessment in ClinicalAssessment.all)
                    if (trends[assessment.id]!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${assessment.id.toUpperCase()} Trend',
                              style: AppTextStyles.body1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: CustomPaint(
                                size: const Size(
                                  double.infinity,
                                  double.infinity,
                                ),
                                painter: _TrendChartPainter(
                                  data: trends[assessment.id]!,
                                  maximumScore: assessment.maximumScore,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                  Text('Past attempts', style: AppTextStyles.heading2),
                  const SizedBox(height: 16),

                  if (attempts.isEmpty)
                    Text(
                      'No attempts yet.',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textMuted,
                      ),
                    )
                  else
                    ...attempts.map((attempt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHistoryItem(context, attempt: attempt),
                      );
                    }),

                  const SizedBox(height: 64),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context, {
    required QuizAttempt attempt,
  }) {
    final title = attempt.quizTitle;
    final date = DateFormat('MMM d, yyyy').format(attempt.completedAt);
    final score = attempt.score.toString();

    return GestureDetector(
      onTap: () {
        context.push(AppRouter.quizResultDetail, extra: {'attempt': attempt});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score: $score',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<double> data;
  final int maximumScore;

  _TrendChartPainter({required this.data, required this.maximumScore});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxData = maximumScore.toDouble();

    if (data.isEmpty) return;

    final pointWidth = size.width / (data.length > 1 ? data.length - 1 : 1);

    final path = Path();
    path.moveTo(0, size.height - (data[0] / maxData) * size.height);

    for (int i = 1; i < data.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (data[i] / maxData) * size.height;
      path.lineTo(x, y);
    }

    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    final pointPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    final pointStroke = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < data.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (data[i] / maxData) * size.height;
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 5, pointStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.maximumScore != maximumScore ||
      oldDelegate.data.toString() != data.toString();
}
