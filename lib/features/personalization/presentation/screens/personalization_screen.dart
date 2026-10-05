import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/personalization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/challenge_selection_widget.dart';
import '../../../../core/widgets/option_selection_widget.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/personalization_data.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<PersonalizationQuestion> get _questions => PersonalizationQuestion.questions;

  // Store answers for each question
  final List<String> _selectedChallenges = [];
  final List<String> _selectedGoals = [];
  String? _selectedAge;
  String? _selectedGender;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishPersonalization() async {
    await PersonalizationService().markComplete();
    if (mounted) context.go(AppRouter.preparingCozy);
  }

  void _nextPage() {
    if (_currentPage < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to preparing cozy screen
      _finishPersonalization();
    }
  }

  void _onChallengeToggle(String challenge) {
    setState(() {
      if (_selectedChallenges.contains(challenge)) {
        _selectedChallenges.remove(challenge);
      } else {
        _selectedChallenges.add(challenge);
      }
    });
  }

  void _onGoalToggle(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  void _onAgeSelect(String age) {
    setState(() {
      _selectedAge = age;
    });
    // Auto-advance with a slight delay to allow the user to see their selection
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nextPage();
    });
  }

  void _onGenderSelect(String gender) {
    setState(() {
      _selectedGender = gender;
    });
    // Auto-advance with a slight delay to allow the user to see their selection
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _nextPage();
    });
  }

  Widget _buildQuestionWidget(PersonalizationQuestion question) {
    switch (question.type) {
      case PersonalizationQuestionType.challenges:
        return ChallengeSelectionWidget(
          challenges: question.options,
          selectedChallenges: _selectedChallenges,
          onChallengeToggle: _onChallengeToggle,
        );
      case PersonalizationQuestionType.goals:
        return OptionSelectionWidget(
          options: question.options,
          selectedOptions: _selectedGoals,
          onOptionToggle: _onGoalToggle,
          allowMultiple: true,
        );
      case PersonalizationQuestionType.age:
        return OptionSelectionWidget(
          options: question.options,
          selectedOptions: _selectedAge != null ? [_selectedAge!] : [],
          onOptionToggle: _onAgeSelect,
          allowMultiple: false,
        );
      case PersonalizationQuestionType.gender:
        return OptionSelectionWidget(
          options: question.options,
          selectedOptions: _selectedGender != null ? [_selectedGender!] : [],
          onOptionToggle: _onGenderSelect,
          allowMultiple: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(Icons.arrow_back, color: AppColors.black),
              )
            : null,
        actions: [
          TextButton(
            onPressed: _finishPersonalization,
            child: Text(
              'Skip',
              style: AppTextStyles.linkText.copyWith(color: AppColors.grey),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              height: 4,
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _questions.length,
                backgroundColor: AppColors.lightGrey,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),

            2.sh,

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        4.sh,

                        // Question title
                        Text(
                          question.title,
                          style: AppTextStyles.heading1.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        2.sh,

                        // Question subtitle
                        Text(
                          question.subtitle,
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.grey,
                          ),
                        ),

                        4.sh,

                        // Question widget
                        Expanded(
                          child: question.type == PersonalizationQuestionType.challenges
                              ? _buildQuestionWidget(question) // Do not scroll bubbles
                              : SingleChildScrollView(
                                  child: _buildQuestionWidget(question), // Lists can scroll
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Next button
            Visibility(
              visible: _questions[_currentPage].type == PersonalizationQuestionType.challenges ||
                       _questions[_currentPage].type == PersonalizationQuestionType.goals,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Padding(
                padding: EdgeInsets.all(6.w),
                child: AppButton(
                  text: 'Next',
                  onPressed: _nextPage,
                  isOutlined: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
