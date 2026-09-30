import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,

        title: Text(
          'Your activity',
          style: AppTextStyles.heading2,
        ),

        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            3.sh,

            // Time period tabs
            SizedBox(
              width: double.infinity,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTab('Week', true)),
                    Expanded(child: _buildTab('Month', false)),
                    Expanded(child: _buildTab('3 Months', false)),
                    Expanded(child: _buildTab('Year', false)),
                  ],
                ),
              ),
            ),

            5.sh,

            // Mood for the week card
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              'Mood for the week:',
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 18,
                              ),
                            ),

                            const Text(
                              '😊',
                              style: TextStyle(fontSize: 24),
                            ),

                            Text(
                              'Amazing',
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  4.sh,

                  // Simple Line Chart
                  SizedBox(
                    height: 180,
                    child: CustomPaint(
                      size: const Size(double.infinity, 180),
                      painter: MoodLineChartPainter(),
                    ),
                  ),

                  2.sh,

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6.w,
                    runSpacing: 1.h,
                    children: [
                      _buildLegend(
                        'This week',
                        AppColors.primary,
                      ),

                      _buildLegend(
                        'Previous week',
                        const Color(0xFF9BE6A6),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            5.sh,

            // General Insights
            Text(
              'General Insights',
              style: AppTextStyles.heading2,
            ),

            3.sh,

            // Cozy Calendar
            _buildInsightCard(
              title: 'Cozy Calendar',
              subtitle:
                  'Collected from the app openings and mood check-ins',
              content: _buildCalendarDots(),
              onViewLog: () {},
            ),

            4.sh,

            // Writing
            _buildInsightCard(
              title: 'Writing',
              subtitle: 'Days when you wrote',
              content: _buildWritingDots(),
              onViewLog: () {},
            ),

            4.sh,

            // Common Triggers
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Common Triggers',
                        style: AppTextStyles.heading2,
                      ),

                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Details',
                          style: AppTextStyles.linkText,
                        ),
                      ),
                    ],
                  ),

                  4.sh,

                  _buildTriggerItem(
                    'Work Stress',
                    '64%',
                    'Medium Impact',
                    const Color(0xFF4ADE80),
                  ),

                  3.sh,

                  _buildTriggerItem(
                    'Exam Stress',
                    '80%',
                    'High Impact',
                    const Color(0xFFFF6B6B),
                  ),

                  3.sh,

                  _buildTriggerItem(
                    'Poor Sleep',
                    '75%',
                    'Medium Impact',
                    const Color(0xFFFFB74D),
                  ),
                ],
              ),
            ),

            6.sh,

            // Recommended
            Text(
              'Recommended for you',
              style: AppTextStyles.heading2,
            ),

            3.sh,

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 4.h,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.88,
              children: [
                _buildRecommendationCard(
                  title:
                      'Mental Health 101: Understanding Anxiety, Depression, and Stress',
                  color: const Color(0xFFE0F2E9),
                  emoji: '🧠',
                ),

                _buildRecommendationCard(
                  title:
                      'Balancing Productivity and Mental Health: How to Avoid Burnout',
                  color: const Color(0xFFFFF4E5),
                  emoji: '⏰',
                ),

                _buildRecommendationCard(
                  title:
                      'The Link Between Diet, Exercise, and Mental Health',
                  color: const Color(0xFFE0F2E9),
                  emoji: '🥗',
                ),

                _buildRecommendationCard(
                  title:
                      'The Role of Gratitude in Improving Mental Health',
                  color: const Color(0xFFFFF4E5),
                  emoji: '🙏',
                ),
              ],
            ),

            12.sh,
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body2.copyWith(
          fontSize: 12,
          color: isActive
              ? AppColors.white
              : AppColors.grey,
          fontWeight: isActive
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        2.sw,

        Text(
          label,
          style: AppTextStyles.body2,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String subtitle,
    required Widget content,
    required VoidCallback onViewLog,
  }) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.heading2,
          ),

          1.sh,

          Text(
            subtitle,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.grey,
            ),
          ),

          4.sh,

          content,

          3.sh,

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewLog,
              child: Text(
                'View Log →',
                style: AppTextStyles.linkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDots() {
    final colors = [
      AppColors.primary,
      const Color(0xFF9BE6A6),
      const Color(0xFFFFD08A),
      const Color(0xFFFFB3D1),
      const Color(0xFFFF8A8A),
    ];

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      alignment: WrapAlignment.spaceBetween,
      children: List.generate(
        7,
        (index) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors[index % colors.length]
                .withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildWritingDots() {
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      alignment: WrapAlignment.spaceBetween,
      children: List.generate(
        7,
        (index) => Icon(
          index < 4
              ? Icons.check_circle
              : Icons.circle_outlined,
          color: index < 4
              ? AppColors.primary
              : AppColors.midGrey,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTriggerItem(
    String trigger,
    String percentage,
    String impact,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                trigger,
                style: AppTextStyles.body1,
              ),

              1.sh,

              LinearProgressIndicator(
                value: double.parse(
                      percentage.replaceAll('%', ''),
                    ) /
                    100,
                backgroundColor:
                    AppColors.lightGrey,
                valueColor:
                    AlwaysStoppedAnimation(color),
                minHeight: 8,
                borderRadius:
                    BorderRadius.circular(4),
              ),
            ],
          ),
        ),

        4.sw,

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Text(
              percentage,
              style:
                  AppTextStyles.heading2.copyWith(
                fontSize: 18,
              ),
            ),

            Text(
              impact,
              style:
                  AppTextStyles.body2.copyWith(
                color: AppColors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required Color color,
    required String emoji,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),

          const Spacer(),

          Text(
            title,
            style:
                AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class MoodLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0460D8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(0, size.height * 0.6);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.75,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.3,
      size.width,
      size.height * 0.55,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}
