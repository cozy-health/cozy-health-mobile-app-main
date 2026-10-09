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
  });
  final String id;
  final String title;
  final List<String> questions;
  final int minutes;
  int get maximumScore => questions.length * 3;
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
    if (total < 5) return 'Minimal';
    if (total < 10) return 'Mild';
    if (total < 15) return 'Moderate';
    if (id == 'phq-9' && total < 20) return 'Moderately Severe';
    return 'Severe';
  }

  // A positive PHQ-9 item 9 warrants support independently of the total.
  // The prompt is optional and must not be presented as a risk diagnosis.
  bool needsSupport(List<int> answers) =>
      score(answers) >= 15 || (id == 'phq-9' && answers[8] > 0);
}
