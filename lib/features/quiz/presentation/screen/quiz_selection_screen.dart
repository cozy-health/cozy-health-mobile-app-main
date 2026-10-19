import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../data/quiz_repository.dart';
import '../../domain/clinical_assessment.dart';
import '../../../../core/widgets/empty_state.dart';

class QuizSelectionScreen extends StatefulWidget {
  const QuizSelectionScreen({
    super.key,
    this.availableQuizIds,
    this.repository,
  });
  final Set<String>? availableQuizIds;
  final QuizRepository? repository;
  @override
  State<QuizSelectionScreen> createState() => _QuizSelectionScreenState();
}

class _QuizSelectionScreenState extends State<QuizSelectionScreen> {
  late final QuizRepository _repository;
  late Future<List<ClinicalAssessment>> _catalog;
  String _category = 'All';
  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? QuizRepository();
    _catalog = widget.availableQuizIds?.isEmpty == true
        ? Future.value([])
        : _repository.catalog();
    _repository.fetchAttempts();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Assessments'),
      actions: [
        IconButton(
          tooltip: 'Shared with me',
          onPressed: () => context.push('/quiz-shared'),
          icon: const Icon(Icons.inbox_outlined),
        ),
        IconButton(
          tooltip: 'Results history',
          onPressed: () => context.push(AppRouter.quizHistory),
          icon: const Icon(Icons.history),
        ),
      ],
    ),
    body: FutureBuilder<List<ClinicalAssessment>>(
      future: _catalog,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Assessments could not be loaded',
            subtitle:
                'Check your connection and try again. Your saved results are still available from Results history.',
            primaryCtaLabel: 'Retry',
            onPrimaryCta: () =>
                setState(() => _catalog = _repository.catalog()),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!
            .where(
              (a) =>
                  widget.availableQuizIds == null ||
                  widget.availableQuizIds!.contains(a.id),
            )
            .toList();
        if (all.isEmpty) {
          return EmptyState(
            icon: Icons.assignment_outlined,
            title: 'No assessments are available yet',
            subtitle:
                'Your care team has not published any approved assessments for this account. You can check again or view your saved results.',
            primaryCtaLabel: 'Retry',
            onPrimaryCta: () =>
                setState(() => _catalog = _repository.catalog()),
          );
        }
        final types = {
          'All',
          ...all.map((a) => a.definition['type'] as String? ?? 'clinical'),
        };
        final assessments = all
            .where(
              (a) => _category == 'All' || a.definition['type'] == _category,
            )
            .toList();
        return StreamBuilder<List<QuizAttempt>>(
          stream: _repository.watchAttempts(),
          builder: (context, attempts) {
            final completed = (attempts.data ?? [])
                .map((a) => a.assessmentId)
                .toSet();
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _catalog = _repository.catalog());
                await _catalog;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (all.isEmpty) ...[
                    const Text(
                      'No approved assessments are available. Connect to refresh the catalog.',
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _catalog = _repository.catalog()),
                      child: const Text('Retry'),
                    ),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final type in types)
                        ChoiceChip(
                          label: Text(type),
                          selected: _category == type,
                          onSelected: (_) => setState(() => _category = type),
                        ),
                    ],
                  ),
                  for (final a in assessments)
                    Card(
                      child: ListTile(
                        title: Text(a.title),
                        subtitle: Text(
                          '${a.questions.length} questions · ${a.minutes} min${completed.contains(a.id) ? ' · Completed' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          AppRouter.quizDetail,
                          extra: {
                            'id': a.id,
                            'type': a.definition['type'],
                            'definition': a.definition,
                          },
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
