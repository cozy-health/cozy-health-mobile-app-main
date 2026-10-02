import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../data/quiz_repository.dart';
import '../widgets/quiz_recommendation_card.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({super.key});

  @override
  State<QuizSelectionScreen> createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = ['All', 'Clinical', 'Wellness', 'Reflection'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text('Quizzes', style: AppTextStyles.heading2),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.text),
            onPressed: () => context.push(AppRouter.quizHistory),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<QuizAttempt>>(
          stream: QuizRepository().watchAttempts(),
          builder: (context, snapshot) {
            final attempts = snapshot.data ?? [];
            final completedIds = attempts.map((a) => a.quizId).toSet();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Recommendation
                  QuizRecommendationCard(
                    onTap: () {
                      context.push(AppRouter.quizDetail, extra: {'type': 'clinical', 'id': 'gad-7'});
                    },
                  ),
                  const SizedBox(height: 32),

                  // Search & Filter
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search quizzes...',
                        hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(
                              cat,
                              style: AppTextStyles.body2.copyWith(
                                color: isSelected ? AppColors.white : AppColors.text,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                            backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            onPressed: () {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quiz List
                  _buildQuizCategory('Clinical Assessments', 'clinical', completedIds),
                  const SizedBox(height: 24),
                  _buildQuizCategory('Wellness', 'wellness', completedIds),
                  const SizedBox(height: 24),
                  _buildQuizCategory('Reflection', 'reflection', completedIds),
                  const SizedBox(height: 64),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildQuizCategory(String title, String type, Set<String> completedIds) {
    if (_selectedCategory != 'All' && _selectedCategory.toLowerCase() != type.toLowerCase()) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        if (type == 'clinical') ...[
          _buildQuizCard(
            title: 'PHQ-9 (Depression)',
            description: 'A standard clinical screening tool for depression severity.',
            duration: '5 min',
            isClinical: true,
            isCompleted: completedIds.contains('phq-9'),
            id: 'phq-9',
          ),
          const SizedBox(height: 12),
          _buildQuizCard(
            title: 'GAD-7 (Anxiety)',
            description: 'Screening tool for generalized anxiety disorder.',
            duration: '3 min',
            isClinical: true,
            isCompleted: completedIds.contains('gad-7'),
            id: 'gad-7',
          ),
        ] else if (type == 'wellness') ...[
          _buildQuizCard(
            title: 'Sleep Hygiene Check',
            description: 'Are your habits helping or hurting your rest?',
            duration: '4 min',
            isClinical: false,
            isCompleted: completedIds.contains('sleep'),
            id: 'sleep',
          ),
        ] else ...[
          _buildQuizCard(
            title: 'Relationship Boundaries',
            description: 'Reflect on how you set boundaries with others.',
            duration: '6 min',
            isClinical: false,
            isCompleted: completedIds.contains('boundaries'),
            id: 'boundaries',
          ),
        ],
      ],
    );
  }

  Widget _buildQuizCard({
    required String title,
    required String description,
    required String duration,
    required bool isClinical,
    required bool isCompleted,
    required String id,
  }) {
    // Clinical uses neutral, Wellness uses warm
    final bgColor = isClinical ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05);
    final borderColor = isClinical ? AppColors.border : AppColors.primary.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () {
        context.push(AppRouter.quizDetail, extra: {
          'id': id,
          'type': isClinical ? 'clinical' : 'wellness',
          'title': title,
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading2.copyWith(fontSize: 18),
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Done',
                          style: AppTextStyles.body2.copyWith(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    duration,
                    style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
