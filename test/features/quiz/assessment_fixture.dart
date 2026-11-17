import 'package:cozy_health/features/quiz/domain/clinical_assessment.dart';

Map<String, dynamic> assessmentFixture(ClinicalAssessment assessment) => {
  'id': 1,
  'slug': assessment.id,
  'title': assessment.title,
  'type': 'clinical',
  'estimated_minutes': assessment.minutes,
  'definition_version': '00000000-0000-4000-8000-000000000001',
  'timeframe': ClinicalAssessment.timeframe,
  'disclaimer':
      'Not a substitute for professional care. This is not a diagnosis.',
  'scoring_rules': {
    'bands': [
      {'max': 4, 'label': 'Minimal'},
      {'max': 9, 'label': 'Mild'},
      {'max': 14, 'label': 'Moderate'},
      if (assessment.id == 'phq-9') {'max': 19, 'label': 'Moderately Severe'},
      {'max': assessment.maximumScore, 'label': 'Severe'},
    ],
  },
  'questions': [
    for (var i = 0; i < assessment.questions.length; i++)
      {
        'id': i + 1,
        'question': assessment.questions[i],
        'options': [
          for (var j = 0; j < 4; j++)
            {
              'id': i * 10 + j + 100,
              'label': ClinicalAssessment.answerLabels[j],
              'score': j,
            },
        ],
      },
  ],
};
