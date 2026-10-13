import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/quiz_repository.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});
  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  final _repository = QuizRepository();
  @override
  void initState() {
    super.initState();
    _repository.fetchAttempts();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Quiz History')),
    body: StreamBuilder<List<QuizAttempt>>(
      stream: _repository.watchAttempts(),
      initialData: LocalDbService().getAllQuizAttempts(),
      builder: (context, snapshot) {
        final attempts = [...?snapshot.data]
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
        final groups = <String, List<QuizAttempt>>{};
        for (final attempt in attempts.reversed) {
          if (!const [
                'validated',
                'pending',
              ].contains(attempt.validationState) ||
              attempt.metadata['maximum_score'] == null) {
            continue;
          }
          final key =
              '${attempt.quizSlug}:${attempt.metadata['definition_version']}:${attempt.metadata['maximum_score']}';
          (groups[key] ??= []).add(attempt);
        }
        return RefreshIndicator(
          onRefresh: () async {
            await _repository.fetchAttempts();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (attempts.isEmpty) ...[
                const Text('Your results will appear here.'),
                TextButton(
                  onPressed: () => context.push('/quiz-selection'),
                  child: const Text('Explore assessments'),
                ),
              ],
              for (final rows in groups.values) _Trend(rows: rows),
              const SizedBox(height: 12),
              Text(
                'Past attempts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final attempt in attempts)
                Card(
                  child: ListTile(
                    title: Text(attempt.quizTitle),
                    subtitle: Text(
                      '${DateFormat.yMMMd().format(attempt.completedAt.toLocal())} · ${attempt.validationState}',
                    ),
                    trailing: Text('${attempt.score}'),
                    onTap: () => context.push('/quiz-attempt/${attempt.id}'),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _Trend extends StatelessWidget {
  const _Trend({required this.rows});
  final List<QuizAttempt> rows;
  @override
  Widget build(BuildContext context) {
    final maximum = rows.first.metadata['maximum_score'] as int;
    final reduced =
        MediaQuery.of(context).disableAnimations ||
        LocalDbService().getUserProfile()?.reduceMotion == true;
    final descriptions = rows
        .map(
          (r) =>
              '${DateFormat.yMMMd().format(r.completedAt.toLocal())}: ${r.score} out of $maximum, ${r.validationState}',
        )
        .join('. ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${rows.first.quizTitle} Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('Scale 0–$maximum · hollow points are provisional'),
            Semantics(
              label: descriptions,
              child: ExcludeSemantics(
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(descriptions),
                  tween: Tween(begin: reduced ? 1 : 0, end: 1),
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 450),
                  builder: (context, progress, _) => SizedBox(
                    height: 140,
                    child: CustomPaint(
                      painter: _TrendPainter(
                        rows,
                        maximum,
                        Theme.of(context).colorScheme.primary,
                        progress,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.MMMd().format(rows.first.completedAt.toLocal()),
                ),
                Text(DateFormat.MMMd().format(rows.last.completedAt.toLocal())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.rows, this.maximum, this.color, this.progress);
  final List<QuizAttempt> rows;
  final int maximum;
  final Color color;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (maximum <= 0 || rows.isEmpty) return;
    const margin = 8.0;
    final width = size.width - margin * 2;
    final height = size.height - margin * 2;
    final first = rows.first.completedAt.millisecondsSinceEpoch;
    final range = rows.last.completedAt.millisecondsSinceEpoch - first;
    final points = rows
        .map(
          (r) => Offset(
            range == 0
                ? size.width / 2
                : margin +
                      (r.completedAt.millisecondsSinceEpoch - first) /
                          range *
                          width,
            margin +
                height -
                r.score.clamp(0, maximum) / maximum * height * progress,
          ),
        )
        .toList();
    final axis = Paint()
      ..color = color.withValues(alpha: .2)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(margin, margin),
      Offset(margin, margin + height),
      axis,
    );
    canvas.drawLine(
      Offset(margin, margin + height),
      Offset(margin + width, margin + height),
      axis,
    );
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        4,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = rows[i].isValidated
              ? PaintingStyle.fill
              : PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.progress != progress || old.color != color || old.rows != rows;
}
