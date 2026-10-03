import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../widgets/quiz_progress_indicator.dart';
import '../widgets/quiz_back_confirm_dialog.dart';

class QuizTakingScreen extends StatefulWidget {
  final Map<String, dynamic> extra;

  const QuizTakingScreen({super.key, required this.extra});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentIndex = 0;
  final int _totalQuestions = 3; // Mock
  int? _selectedIndex;
  int _score = 0;
  final List<int> _answers = [];

  final List<String> _questions = [
    'Little interest or pleasure in doing things?',
    'Feeling down, depressed, or hopeless?',
    'Trouble falling or staying asleep, or sleeping too much?',
  ];

  final List<String> _options = [
    'Not at all',
    'Several days',
    'More than half the days',
    'Nearly every day',
  ];

  Future<bool> _onWillPop() async {
    final result = await QuizBackConfirmDialog.show(context);
    return result ?? false;
  }

  void _nextQuestion() {
    if (_selectedIndex == null) return;
    
    // Simple mock scoring
    _score += _selectedIndex!;
    _answers.add(_selectedIndex!);

    if (_currentIndex < _totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
      });
    } else {
      context.pushReplacement(
        AppRouter.quizResults, 
        extra: {
          ...widget.extra,
          'score': _score,
          'answers': _answers,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check for reduce motion
    final bool reduceMotion = MediaQuery.of(context).accessibleNavigation;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final res = await _onWillPop();
        if (res == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: AppColors.text),
            onPressed: () async {
              final res = await _onWillPop();
              if (res == true && context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QuizProgressIndicator(
                  currentIndex: _currentIndex + 1,
                  totalQuestions: _totalQuestions,
                ),
                const SizedBox(height: 32),
                
                Semantics(
                  header: true,
                  child: Text(
                    _questions[_currentIndex],
                    style: AppTextStyles.heading1.copyWith(fontSize: 24, color: AppColors.text, height: 1.3),
                  ),
                ),
                const SizedBox(height: 32),
                
                Expanded(
                  child: ListView.separated(
                    itemCount: _options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      
                      Widget card = GestureDetector(
                        onTap: () => setState(() => _selectedIndex = index),
                        child: Semantics(
                          button: true,
                          selected: isSelected,
                          label: _options[index],
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _options[index],
                                    style: AppTextStyles.body1.copyWith(
                                      color: isSelected ? Theme.of(context).colorScheme.primary : AppColors.text,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (reduceMotion) {
                        return card;
                      }

                      // Only animate on first load or question change
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('q${_currentIndex}_opt$index'),
                        duration: Duration(milliseconds: 300 + (index * 100)),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: card,
                      );
                    },
                  ),
                ),
                
                AppButton(
                  text: _currentIndex < _totalQuestions - 1 ? 'Next' : 'Finish',
                  onPressed: _selectedIndex != null ? _nextQuestion : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
