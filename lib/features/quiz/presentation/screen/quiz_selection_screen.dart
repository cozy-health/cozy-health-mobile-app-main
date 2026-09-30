import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../../../gen/assets.gen.dart';

import '../../data/quiz_service.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({super.key});

  @override
  State<QuizSelectionScreen> createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  final QuizService _quizService = QuizService();

  bool _loading = true;
  String? _error;
  List<dynamic> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _quizService.getQuizzes();

      setState(() {
        _quizzes = response['quizzes'] as List<dynamic>? ?? [];
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load quizzes.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  AssetGenImage _quizImage(int index) {
    final images = [
      Assets.png.emotionalWellbeing,
      Assets.png.stressandanxiety,
      Assets.png.depression,
      Assets.png.socialRelationship,
      Assets.png.copingandresilence,
    ];

    return images[index % images.length];
  }

  Color _quizColor(int index) {
    final colors = [
      const Color(0xFFF0F4FF),
      const Color(0xFFFFF0F0),
      const Color(0xFFF0FFF0),
      const Color(0xFFFFF0F8),
      const Color(0xFFF8F0FF),
    ];

    return colors[index % colors.length];
  }

  String _duration(Map<String, dynamic> quiz) {
    return quiz['duration']?.toString() ??
        quiz['estimated_duration']?.toString() ??
        '5 Min';
  }

  void _openQuizDetail(Map<String, dynamic> quiz) {
    context.push(
      AppRouter.quizDetail,
      extra: {
        'id': quiz['id'],
        'title': quiz['title']?.toString() ?? 'Mental Health Quiz',
        'type': quiz['type']?.toString() ?? 'general',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      _error!,
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadQuizzes,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        2.sh,

                        Text(
                          'Understand your emotions, identify patterns, and receive personalized recommendations to support your journey.',
                          style: AppTextStyles.body1,
                        ),

                        5.sh,

                        if (_quizzes.isEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: 10.h),
                            child: Center(
                              child: Text(
                                'No quizzes available yet.',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            itemCount: _quizzes.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 4.w,
                              mainAxisSpacing: 4.h,
                              childAspectRatio: 0.85,
                            ),
                            itemBuilder: (context, index) {
                              final quiz =
                                  _quizzes[index] as Map<String, dynamic>;

                              return _buildQuizCard(
                                title: quiz['title']?.toString() ??
                                    'Mental Health Quiz',
                                duration: _duration(quiz),
                                color: _quizColor(index),
                                image: _quizImage(index),
                                onTap: () => _openQuizDetail(quiz),
                              );
                            },
                          ),

                        8.sh,
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildQuizCard({
    required String title,
    required String duration,
    required Color color,
    required AssetGenImage image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    duration,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              2.sh,

              Expanded(
                child: Center(
                  child: image.image(
                    height: 85,
                    width: 85,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              3.sh,

              Text(
                title,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}