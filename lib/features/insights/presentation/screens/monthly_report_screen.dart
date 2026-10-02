import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class MonthlyReportScreen extends StatelessWidget {
  const MonthlyReportScreen({super.key});

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
        title: Text('Monthly report', style: AppTextStyles.heading2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: AppColors.text),
                    onPressed: () {},
                  ),
                  Text(
                    'October 2026',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onPressed: () {},
                  ),
                ],
              ),
              SizedBox(height: 24),

              Text(
                'October was\na steady month.',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 24,
                  color: AppColors.text,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 32),

              // Stats
              Container(
                padding: const EdgeInsets.all(20),
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
                    _buildStatRow('28', 'entries'),
                    SizedBox(height: 12),
                    _buildStatRow('6.1', 'avg mood'),
                    SizedBox(height: 12),
                    _buildStatRow('7.2', 'avg sleep'),
                    SizedBox(height: 12),
                    _buildStatRow('4-day', 'longest streak'),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Full width chart
              Container(
                padding: const EdgeInsets.all(20),
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
                      'Mood trend over the month',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _MonthlyAreaChartPainter(),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Top Triggers
              Container(
                padding: const EdgeInsets.all(20),
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
                      'Top triggers',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Work, Sleep, Family',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // What helped
              Container(
                padding: const EdgeInsets.all(20),
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
                      'What helped',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Journaling, Movement',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              AppButton(
                text: 'Export for provider',
                trailingIcon: Icons.description_outlined,
                onPressed: () {
                  // Trigger export
                },
              ),
              SizedBox(height: 16),
              AppButton(
                text: 'Download PDF',
                trailingIcon: Icons.download_outlined,
                isOutlined: true,
                onPressed: () {
                  // Trigger download
                },
              ),
              SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String value, String label) {
    return Row(
      children: [
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _MonthlyAreaChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mock monthly data (about 30 points)
    final List<double> data = [
      5,
      6,
      6,
      7,
      5,
      4,
      6,
      7,
      8,
      8,
      7,
      6,
      5,
      5,
      6,
      7,
      7,
      8,
      9,
      8,
      7,
      6,
      5,
      6,
      7,
      8,
      8,
      7,
      6,
      7,
    ];

    final double maxData = 10;
    final double pointWidth = size.width / (data.length - 1);

    final path = Path();
    final areaPath = Path();

    areaPath.moveTo(0, size.height);
    path.moveTo(0, size.height - (data[0] / maxData) * size.height);
    areaPath.lineTo(0, size.height - (data[0] / maxData) * size.height);

    for (int i = 1; i < data.length; i++) {
      final x = i * pointWidth;
      final y = size.height - (data[i] / maxData) * size.height;

      path.lineTo(x, y);
      areaPath.lineTo(x, y);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Fill gradient
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, paint);

    // Line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MonthlyAreaChartPainter oldDelegate) => false;
}
