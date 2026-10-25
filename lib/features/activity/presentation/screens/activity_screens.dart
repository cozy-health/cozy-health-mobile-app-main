import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/models/journal_entry.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/repositories/journal_repository.dart';
import '../../../../core/repositories/mood_repository.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../content/presentation/widgets/recommended_article_grid.dart';
import '../../../content/data/published_articles_repository.dart';
import '../../data/activity_summary.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, this.articlesRepository});
  final PublishedArticlesRepository? articlesRepository;
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Stream<List<MoodEntry>> _moods;
  late Stream<List<JournalEntry>> _journals;
  int _period = 0;
  bool _showData = false;
  final _days = const [7, 30, 90, 365];
  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    _moods = MoodRepository().watchMoodEntries();
    _journals = JournalRepository().watchJournalEntries();
  }

  String _range(DateTime a, DateTime b) =>
      '${DateFormat('d MMM').format(a)}–${DateFormat('d MMM y').format(activityDateOffset(b, -1))}';
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    Widget heading(String label) => Padding(
      padding: EdgeInsets.only(top: w.sectionSpacing, bottom: w.contentGap),
      child: Text(
        label,
        style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      body: SafeArea(
        child: StreamBuilder<List<MoodEntry>>(
          stream: _moods,
          builder: (context, moods) => StreamBuilder<List<JournalEntry>>(
            stream: _journals,
            builder: (context, journals) {
              final loading =
                  (moods.connectionState == ConnectionState.waiting &&
                      !moods.hasData) ||
                  (journals.connectionState == ConnectionState.waiting &&
                      !journals.hasData);
              final s = ActivitySummary(
                moods: moods.data ?? [],
                journals: journals.data ?? [],
                days: _days[_period],
                now: DateTime.now(),
              );
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  w.page,
                  w.contentGap,
                  w.page,
                  wellnessFloatingClearance(context),
                ),
                children: [
                  Text(
                    'Your activity',
                    style: t.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: w.tight),
                  Text(
                    'A little perspective on your activity.',
                    style: t.textTheme.bodyMedium,
                  ),
                  SizedBox(height: w.sectionSpacing),
                  WellnessSegments(
                    labels: const ['Week', 'Month', '3 Months', 'Year'],
                    selected: _period,
                    onSelected: (i) => setState(() => _period = i),
                    keyPrefix: 'activity-period',
                  ),
                  SizedBox(height: w.contentGap),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _range(s.start, s.end),
                          style: t.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppPressable(
                        label: 'Open mood history',
                        onPressed: () => context.push(AppRouter.moodHistory),
                        child: SizedBox(
                          width: w.touch,
                          height: w.touch,
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (moods.hasError || journals.hasError) ...[
                    WellnessPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Some activity could not be loaded. Available records are shown below.',
                          ),
                          WellnessAction(
                            label: 'Retry activity',
                            onPressed: () => setState(_watch),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: w.contentGap),
                  ],
                  WellnessPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVERAGE INTENSITY',
                          style: t.textTheme.labelMedium,
                        ),
                        SizedBox(height: w.small),
                        Wrap(
                          spacing: w.small,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              s.average?.toStringAsFixed(1) ?? '—',
                              style: t.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text('/ 5'),
                          ],
                        ),
                        Text(
                          _comparison(s),
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: w.gap),
                        if (s.average != null || s.previousAverage != null) ...[
                          Semantics(
                            label:
                                'Intensity from 1 to 5. Current ${s.average?.toStringAsFixed(1) ?? 'no data'}, previous ${s.previousAverage?.toStringAsFixed(1) ?? 'no data'}. Open chart data for individual values.',
                            child: ExcludeSemantics(
                              child: SizedBox(
                                width: double.infinity,
                                height: 180,
                                child: CustomPaint(
                                  painter: _IntensityChart(
                                    s,
                                    c,
                                    t.textTheme.bodySmall,
                                    MediaQuery.textScalerOf(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: w.contentGap),
                          Wrap(
                            spacing: w.gap,
                            runSpacing: w.small,
                            children: [
                              _legend('This period', false),
                              _legend('Previous period', true),
                            ],
                          ),
                          SizedBox(height: w.small),
                          Text(
                            'Compared with ${_range(activityDateOffset(s.start, -s.days), s.start)}',
                            style: t.textTheme.bodySmall,
                          ),
                          WellnessAction(
                            label: _showData
                                ? 'Hide chart data'
                                : 'View chart data',
                            onPressed: () =>
                                setState(() => _showData = !_showData),
                          ),
                          if (_showData)
                            ...s.buckets.map(
                              (b) => Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: w.small,
                                ),
                                child: Text(
                                  '${DateFormat('d MMM').format(b.start)}–${DateFormat('d MMM').format(activityDateOffset(b.end, -1))}: ${b.current?.toStringAsFixed(1) ?? 'No check-in'}; previous ${b.previous?.toStringAsFixed(1) ?? 'No check-in'}',
                                ),
                              ),
                            ),
                        ],
                        Text(
                          'Intensity measures strength, from 1 to 5. Gaps mean no check-in.',
                          style: t.textTheme.bodySmall,
                        ),
                        if (!loading && s.average == null) ...[
                          SizedBox(height: w.contentGap),
                          WellnessAction(
                            label: 'Record a check-in',
                            onPressed: () =>
                                context.push(AppRouter.moodFeeling),
                          ),
                        ],
                      ],
                    ),
                  ),
                  heading('Your check-in rhythm'),
                  WellnessPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.checkedDays.length} of 7 days checked in',
                          style: t.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: w.contentGap),
                        Row(
                          children: [
                            for (final day in s.rhythmDates)
                              Expanded(
                                child: Semantics(
                                  label:
                                      '${DateFormat.yMMMMd().format(day)}: ${s.checkedDays.contains(day) ? 'checked in' : 'no check-in'}',
                                  child: ExcludeSemantics(
                                    child: Column(
                                      children: [
                                        Text(
                                          DateFormat('EEEEE').format(day),
                                          style: t.textTheme.labelSmall,
                                        ),
                                        SizedBox(height: w.small),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: s.checkedDays.contains(day)
                                                ? w.accentPanel(c)
                                                : c.surface,
                                            border: Border.all(
                                              color: day == s.today
                                                  ? c.onSurface
                                                  : c.outlineVariant,
                                            ),
                                          ),
                                          child: Icon(
                                            s.checkedDays.contains(day)
                                                ? Icons.check_rounded
                                                : Icons.remove_rounded,
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(height: w.tight),
                                        Text(
                                          '${day.day}',
                                          style: t.textTheme.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: w.contentGap),
                        WellnessAction(
                          label: 'View mood log',
                          onPressed: () => context.push(AppRouter.moodHistory),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: w.contentGap),
                  AppPressable(
                    label:
                        'Open journal, current writing streak ${s.writingStreak} days',
                    onPressed: () => context.push(AppRouter.journal),
                    child: WellnessPanel(
                      tinted: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 28),
                          SizedBox(width: w.contentGap),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'A ${s.writingStreak}-day writing streak',
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: w.tight),
                                const Text('Your current streak, as of today.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  heading('Common causes'),
                  WellnessPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mentioned across ${s.entries.length} check-ins'),
                        SizedBox(height: w.gap),
                        if (s.causes.isEmpty)
                          const Text('Causes you record will appear here.'),
                        for (final cause in s.causes.take(3)) ...[
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cause.label,
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: w.small),
                              Text('${cause.count} of ${s.entries.length}'),
                            ],
                          ),
                          SizedBox(height: w.small),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(w.small),
                            child: LinearProgressIndicator(
                              value: cause.count / s.entries.length,
                              minHeight: 6,
                              color: c.primary,
                              backgroundColor: c.outlineVariant,
                            ),
                          ),
                          SizedBox(height: w.contentGap),
                        ],
                        Text(
                          'A check-in can include more than one cause.',
                          style: t.textTheme.bodySmall,
                        ),
                        SizedBox(height: w.small),
                        WellnessAction(
                          label: 'Explore causes',
                          onPressed: () =>
                              context.push(AppRouter.insightsTriggers),
                        ),
                      ],
                    ),
                  ),
                  heading('Recommended for you'),
                  const Text('A few thoughtful reads for your day.'),
                  SizedBox(height: w.contentGap),
                  RecommendedArticles(repository: widget.articlesRepository),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _comparison(ActivitySummary s) {
    if (s.average == null) return 'No check-ins in this period yet.';
    if (s.previousAverage == null) {
      return 'No check-ins in the previous period to compare.';
    }
    final change = s.average! - s.previousAverage!;
    return change.abs() < .05
        ? 'The same as the previous period'
        : '${change.abs().toStringAsFixed(1)} ${change > 0 ? 'higher' : 'lower'} than the previous period';
  }

  Widget _legend(String label, bool dashed) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomPaint(
        size: const Size(24, 12),
        painter: _ChartSwatch(Theme.of(context).colorScheme, dashed),
      ),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ChartSwatch extends CustomPainter {
  _ChartSwatch(this.c, this.dashed);
  final ColorScheme c;
  final bool dashed;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = (dashed ? c.onSurfaceVariant : c.primary)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += dashed ? 8 : size.width) {
      canvas.drawLine(
        Offset(x, 6),
        Offset(math.min(x + (dashed ? 4 : size.width), size.width), 6),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChartSwatch old) =>
      old.c != c || old.dashed != dashed;
}

class _IntensityChart extends CustomPainter {
  _IntensityChart(this.s, this.c, this.style, this.scaler);
  final ActivitySummary s;
  final ColorScheme c;
  final TextStyle? style;
  final TextScaler scaler;
  @override
  void paint(Canvas canvas, Size size) {
    final fontSize = scaler.scale(11),
        left = fontSize + 12,
        right = size.width - 8,
        top = fontSize,
        bottom = size.height - fontSize * 2 - 8;
    Offset point(int i, double v) => Offset(
      left + i * (right - left) / 6,
      bottom - (v - 1) * (bottom - top) / 4,
    );
    void text(String str, Offset pos) {
      final p = TextPainter(
        text: TextSpan(
          text: str,
          style: style?.copyWith(color: c.onSurfaceVariant, fontSize: fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, pos);
      p.dispose();
    }

    for (var v = 1; v <= 5; v++) {
      final y = point(0, v.toDouble()).dy;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()..color = c.outlineVariant,
      );
      text('$v', Offset(0, y - fontSize / 2));
    }
    for (var i = 0; i < 7; i++) {
      text(
        s.days <= 30
            ? '${s.buckets[i].start.day}'
            : DateFormat('MMM').format(s.buckets[i].start),
        Offset(point(i, 1).dx - fontSize / 2, bottom + 8),
      );
      for (final previous in [true, false]) {
        final v = previous ? s.buckets[i].previous : s.buckets[i].current;
        if (v == null) continue;
        final p = Paint()
          ..color = (previous ? c.onSurfaceVariant : c.primary)
          ..strokeWidth = (previous ? 1.5 : 2.5);
        final last = i > 0
            ? (previous ? s.buckets[i - 1].previous : s.buckets[i - 1].current)
            : null;
        if (last != null) {
          final a = point(i - 1, last), b = point(i, v);
          if (previous) {
            for (double d = 0; d < 1; d += .19) {
              canvas.drawLine(
                Offset.lerp(a, b, d)!,
                Offset.lerp(a, b, math.min(d + .09, 1))!,
                p,
              );
            }
          } else {
            canvas.drawLine(a, b, p);
          }
        }
        canvas.drawCircle(point(i, v), previous ? 2 : 4, p);
        if (!previous) {
          canvas.drawCircle(point(i, v), 2, Paint()..color = c.surface);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IntensityChart old) =>
      old.s != s || old.c != c || old.scaler != scaler;
}
