import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/activity_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final ActivityService _activityService = ActivityService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _overview = {};
  List<dynamic> _chart = [];
  List<dynamic> _triggers = [];
  Map<String, dynamic> _journalStats = {};
  List<dynamic> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _activityService.getOverview(),
        _activityService.getMoodChart(days: 7),
        _activityService.getCommonTriggers(),
        _activityService.getJournalStats(),
        _activityService.getRecommendations(),
      ]);

      setState(() {
        _overview = results[0]['overview'] as Map<String, dynamic>? ?? {};
        _chart = results[1]['chart'] as List<dynamic>? ?? [];
        _triggers = results[2]['triggers'] as List<dynamic>? ?? [];
        _journalStats = results[3]['stats'] as Map<String, dynamic>? ?? {};
        _recommendations =
            results[4]['recommendations'] as List<dynamic>? ?? [];
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to load activity data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _weeklyMood {
    if (_chart.isEmpty) return 'No data yet';

    final latest = _chart.firstWhere(
      (item) => item is Map && item['feeling'] != null,
      orElse: () => null,
    );

    if (latest is Map && latest['feeling'] != null) {
      return latest['feeling'].toString();
    }

    return 'Tracked';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Your activity', style: AppTextStyles.heading2),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppColors.primary),
            onPressed: _loadActivity,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      _error!,
                      style: AppTextStyles.body1.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadActivity,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        3.sh,

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

                        _buildOverviewCard(),

                        5.sh,

                        _buildMoodCard(),

                        5.sh,

                        Text('General Insights', style: AppTextStyles.heading2),

                        3.sh,

                        _buildInsightCard(
                          title: 'Cozy Calendar',
                          subtitle:
                              'Collected from the app openings and mood check-ins',
                          content: _buildCalendarDots(),
                          onViewLog: () {},
                        ),

                        4.sh,

                        _buildInsightCard(
                          title: 'Writing',
                          subtitle: 'Days when you wrote',
                          content: _buildWritingDots(),
                          onViewLog: () {},
                        ),

                        4.sh,

                        _buildTriggersCard(),

                        6.sh,

                        Text(
                          'Recommended for you',
                          style: AppTextStyles.heading2,
                        ),

                        3.sh,

                        _buildRecommendations(),

                        12.sh,
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 5.w,
        runSpacing: 2.h,
        children: [
          _overviewItem(
            'Check-ins',
            _overview['mood_checkins']?.toString() ?? '0',
          ),
          _overviewItem(
            'Journals',
            _overview['journals']?.toString() ?? '0',
          ),
          _overviewItem(
            'Coping',
            _overview['coping_actions']?.toString() ?? '0',
          ),
          _overviewItem(
            'Streak',
            '${_overview['current_streak'] ?? 0} days',
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(String label, String value) {
    return SizedBox(
      width: 35.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          0.8.sh,
          Text(
            label,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
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
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Text(
                'Mood for the week:',
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              const Text('😊', style: TextStyle(fontSize: 24)),
              Text(
                _weeklyMood,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          4.sh,

          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: MoodLineChartPainter(chart: _chart),
            ),
          ),

          2.sh,

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6.w,
            runSpacing: 1.h,
            children: [
              _buildLegend('This week', AppColors.primary),
              _buildLegend('Previous week', const Color(0xFF9BE6A6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTriggersCard() {
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Common Triggers', style: AppTextStyles.heading2),
              TextButton(
                onPressed: () {},
                child: Text('Details', style: AppTextStyles.linkText),
              ),
            ],
          ),

          4.sh,

          if (_triggers.isEmpty)
            Text(
              'No triggers recorded yet.',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey),
            )
          else
            ..._triggers.map((item) {
              final trigger = item as Map<String, dynamic>;
              final name = trigger['name']?.toString() ?? 'Unknown';
              final percentage = trigger['percentage']?.toString() ?? '0';

              return Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: _buildTriggerItem(
                  name,
                  '$percentage%',
                  _impactLabel(int.tryParse(percentage) ?? 0),
                  _impactColor(int.tryParse(percentage) ?? 0),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _impactLabel(int percentage) {
    if (percentage >= 70) return 'High Impact';
    if (percentage >= 40) return 'Medium Impact';
    return 'Low Impact';
  }

  Color _impactColor(int percentage) {
    if (percentage >= 70) return const Color(0xFFFF6B6B);
    if (percentage >= 40) return const Color(0xFFFFB74D);
    return const Color(0xFF4ADE80);
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) {
      return Text(
        'No recommendations yet.',
        style: AppTextStyles.body2.copyWith(color: AppColors.grey),
      );
    }

    return GridView.builder(
  itemCount: _recommendations.length > 4
      ? 4
      : _recommendations.length,

  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),

  gridDelegate:
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 4.w,
    mainAxisSpacing: 4.h,
    childAspectRatio: 0.88,
  ),

  itemBuilder: (context, index) {
    final item =
        _recommendations[index] as Map<String, dynamic>;

    return _buildRecommendationCard(
      title:
          item['title']?.toString() ??
          item['name']?.toString() ??
          'Recommended Resource',

      color: index.isEven
          ? const Color(0xFFE0F2E9)
          : const Color(0xFFFFF4E5),

      emoji: index.isEven ? '🧠' : '⏰',
    );
  },
);
  }

  Widget _buildTab(String text, bool isActive) {
    return Container(
      height: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body2.copyWith(
          fontSize: 12,
          color: isActive ? AppColors.white : AppColors.grey,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        2.sw,
        Text(label, style: AppTextStyles.body2),
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
          Text(title, style: AppTextStyles.heading2),
          1.sh,
          Text(
            subtitle,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey),
          ),
          4.sh,
          content,
          3.sh,
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onViewLog,
              child: Text('View Log →', style: AppTextStyles.linkText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDots() {
    final checkins = int.tryParse(
          _overview['mood_checkins']?.toString() ?? '0',
        ) ??
        0;

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
            color: index < checkins
                ? colors[index % colors.length].withOpacity(0.5)
                : AppColors.lightGrey,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildWritingDots() {
    final thisWeek = int.tryParse(
          _journalStats['this_week']?.toString() ?? '0',
        ) ??
        0;

    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      alignment: WrapAlignment.spaceBetween,
      children: List.generate(
        7,
        (index) => Icon(
          index < thisWeek ? Icons.check_circle : Icons.circle_outlined,
          color: index < thisWeek ? AppColors.primary : AppColors.midGrey,
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
    final value =
        (double.tryParse(percentage.replaceAll('%', '')) ?? 0) / 100;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trigger, style: AppTextStyles.body1),
              1.sh,
              LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.lightGrey,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
        4.sw,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              percentage,
              style: AppTextStyles.heading2.copyWith(fontSize: 18),
            ),
            Text(
              impact,
              style: AppTextStyles.body2.copyWith(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const Spacer(),
          Text(
            title,
            style: AppTextStyles.body1.copyWith(
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
  final List<dynamic> chart;

  MoodLineChartPainter({required this.chart});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0460D8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();

    final values = chart
        .map((item) {
          if (item is Map && item['intensity'] != null) {
            return double.tryParse(item['intensity'].toString()) ?? 5;
          }
          return 5.0;
        })
        .toList();

    if (values.isEmpty) {
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
      return;
    }

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : (size.width / (values.length - 1)) * i;
      final normalized = values[i].clamp(1, 10) / 10;
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant MoodLineChartPainter oldDelegate) {
    return oldDelegate.chart != chart;
  }
}