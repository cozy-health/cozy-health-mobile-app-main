/// Published instrument wording:
/// https://www.hiv.uw.edu/page/mental-health-screening/phq-9
/// https://www.hiv.uw.edu/page/mental-health-screening/gad-7
/// These are screening instruments, not diagnoses.
class ClinicalAssessment {
  const ClinicalAssessment({
    required this.id,
    required this.title,
    required this.questions,
    required this.minutes,
    this.definitionVersion,
    this.definition = const {},
  });
  final String id;
  final String title;
  final List<String> questions;
  final int minutes;
  final String? definitionVersion;
  final Map<String, dynamic> definition;
  List<Map<String, dynamic>> get questionDefinitions =>
      (definition['questions'] as List? ?? [])
          .map((q) => Map<String, dynamic>.from(q as Map))
          .toList();
  List<Map<String, dynamic>> options(int question) => definition.isEmpty
      ? [
          for (var i = 0; i < answerLabels.length; i++)
            {'id': i, 'label': answerLabels[i], 'score': i},
        ]
      : (questionDefinitions[question]['options'] as List)
            .map((o) => Map<String, dynamic>.from(o as Map))
            .toList();
  String get questionTimeframe =>
      definition['timeframe'] as String? ?? timeframe;
  String get disclaimer =>
      definition['disclaimer'] as String? ??
      'Not a substitute for professional care. This is not a diagnosis.';
  String recommendation(int total) {
    final rules = definition['scoring_rules'] as Map?;
    if (rules == null) return '';
    final band = (rules['bands'] as List).cast<Map>().firstWhere(
      (b) => total <= (b['max'] as num),
    );
    return (band['recommendation'] ?? rules['recommendation'] ?? '').toString();
  }

  int get maximumScore => List.generate(
    questions.length,
    (i) => options(
      i,
    ).map((o) => o['score'] as int).reduce((a, b) => a > b ? a : b),
  ).fold(0, (a, b) => a + b);
  factory ClinicalAssessment.fromDefinition(Map<String, dynamic> json) =>
      ClinicalAssessment(
        id: json['slug'] as String,
        title: json['title'] as String,
        questions: (json['questions'] as List)
            .map((q) => (q as Map)['question'] as String)
            .toList(),
        minutes: (json['estimated_minutes'] as num?)?.toInt() ?? 5,
        definitionVersion: json['definition_version'] as String?,
        definition: json,
      );
  static ClinicalAssessment? fromExtra(Map<String, dynamic> extra) =>
      extra['definition'] is Map
      ? ClinicalAssessment.fromDefinition(
          Map<String, dynamic>.from(extra['definition'] as Map),
        )
      : find(extra['id'] as String?);
  static const timeframe =
      'Over the last 2 weeks, how often have you been bothered by the following problems?';
  static const answerLabels = [
    'Not at all',
    'Several days',
    'More than half the days',
    'Nearly every day',
  ];
  static const phq9 = ClinicalAssessment(
    id: 'phq-9',
    title: 'PHQ-9 Depression Screening',
    minutes: 5,
    questions: [
      'Little interest or pleasure in doing things',
      'Feeling down, depressed or hopeless',
      'Trouble falling asleep, staying asleep, or sleeping too much',
      'Feeling tired or having little energy',
      'Poor appetite or overeating',
      "Feeling bad about yourself - or that you're a failure or have let yourself or your family down",
      'Trouble concentrating on things, such as reading the newspaper or watching television',
      'Moving or speaking so slowly that other people could have noticed. Or, the opposite - being so fidgety or restless that you have been moving around a lot more than usual',
      'Thoughts that you would be better off dead or of hurting yourself in some way',
    ],
  );
  static const gad7 = ClinicalAssessment(
    id: 'gad-7',
    title: 'GAD-7 Anxiety Assessment',
    minutes: 3,
    questions: [
      'Feeling nervous, anxious or on edge',
      'Not being able to stop or control worrying',
      'Worrying too much about different things',
      'Trouble relaxing',
      'Being so restless that it is hard to sit still',
      'Becoming easily annoyed or irritable',
      'Feeling afraid as if something awful might happen',
    ],
  );
  static const all = [phq9, gad7];
  // Retained for existing hidden routes; excluded from the clinical chooser.
  static const legacyAssessments = {
    'sleep': {
      'title': 'Sleep Hygiene Check',
      'description': 'Are your habits helping or hurting your rest?',
      'duration': '4 min',
      'type': 'wellness',
    },
    'boundaries': {
      'title': 'Relationship Boundaries',
      'description': 'Reflect on how you set boundaries with others.',
      'duration': '6 min',
      'type': 'wellness',
    },
  };
  static ClinicalAssessment? find(String? id) {
    for (final assessment in all) {
      if (assessment.id == id) return assessment;
    }
    return null;
  }

  int score(List<int> answers) {
    if (definition.isNotEmpty) {
      if (answers.length != questions.length) {
        throw ArgumentError('Complete every question.');
      }
      var total = 0;
      for (var i = 0; i < answers.length; i++) {
        final option = options(i).where((o) => o['id'] == answers[i]);
        if (option.isEmpty) throw ArgumentError('Invalid answer.');
        total += option.first['score'] as int;
      }
      return total;
    }
    if (answers.length != questions.length ||
        answers.any((answer) => answer < 0 || answer > 3)) {
      throw ArgumentError(
        'A complete assessment requires one answer from 0 to 3 per question.',
      );
    }
    return answers.fold(0, (sum, answer) => sum + answer);
  }

  String severity(int total) {
    if (total < 0 || total > maximumScore) {
      throw RangeError.range(total, 0, maximumScore);
    }
    if (definition.isNotEmpty) {
      final rules = definition['scoring_rules'] as Map;
      return (rules['bands'] as List).cast<Map>().firstWhere(
            (b) => total <= (b['max'] as num),
          )['label']
          as String;
    }
    if (total < 5) return 'Minimal';
    if (total < 10) return 'Mild';
    if (total < 15) return 'Moderate';
    if (id == 'phq-9' && total < 20) return 'Moderately Severe';
    return 'Severe';
  }

  // A positive PHQ-9 item 9 warrants support independently of the total.
  // The prompt is optional and must not be presented as a risk diagnosis.
  bool needsSupport(List<int> answers) {
    final total = score(answers);
    final item9 =
        id == 'phq-9' &&
        answers.length == 9 &&
        options(8).any((o) => o['id'] == answers[8] && (o['score'] as num) > 0);
    final threshold =
        (definition['scoring_rules'] as Map?)?['crisis_threshold'] as num?;
    return item9 ||
        (const ['phq-9', 'gad-7'].contains(id) && total >= 15) ||
        (threshold != null && total >= threshold);
  }
}
