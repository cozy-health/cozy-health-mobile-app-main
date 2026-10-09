import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../gen/assets.gen.dart';
import '../../data/quiz_repository.dart';
import '../../domain/clinical_assessment.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({
    super.key,
    this.availableQuizIds = const {'phq-9', 'gad-7', 'sleep', 'boundaries'},
  });
  final Set<String> availableQuizIds;
  @override
  State<QuizSelectionScreen> createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: BackButton(onPressed: () => context.pop()),
      actions: [
        IconButton(
          tooltip: 'Results history',
          onPressed: () => context.push(AppRouter.quizHistory),
          icon: const Icon(Icons.history),
        ),
      ],
    ),
    body: SafeArea(
      child: StreamBuilder<List<QuizAttempt>>(
        stream: QuizRepository().watchAttempts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const ListSkeleton();
          }
          final assessments = ClinicalAssessment.all
              .where((item) => widget.availableQuizIds.contains(item.id))
              .toList();
          if (assessments.isEmpty) {
            return const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'Assessments coming soon.',
            );
          }
          final completed = (snapshot.data ?? [])
              .map((attempt) => attempt.assessmentId)
              .toSet();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Mental Health Quiz',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
                  final width = (constraints.maxWidth - 20) / 2;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 12,
                    children: [
                      for (final assessment in assessments)
                        SizedBox(
                          width: width,
                          child: Semantics(
                            button: true,
                            child: Material(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.surfaceSubtleDark
                                  : AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => context.push(
                                  AppRouter.quizDetail,
                                  extra: {
                                    'id': assessment.id,
                                    'type': 'clinical',
                                    'title': assessment.title,
                                  },
                                ),
                                child: Container(
                                  constraints: BoxConstraints(
                                    minHeight: 191 * scale,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Image.asset(
                                          assessment.id == 'phq-9'
                                              ? Assets
                                                    .png
                                                    .emotionalWellbeing
                                                    .path
                                              : Assets
                                                    .png
                                                    .stressandanxiety
                                                    .path,
                                          height: 95,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        assessment.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${assessment.questions.length} questions · ${assessment.minutes} min',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      if (completed.contains(assessment.id))
                                        Text(
                                          'Completed',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    ),
  );
}
